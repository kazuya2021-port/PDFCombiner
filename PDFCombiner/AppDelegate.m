//
//  AppDelegate.m
//  PDFCombiner
//
//  Created by uchiyama_Macmini on 2019/06/07.
//  Copyright © 2019年 uchiyama_Macmini. All rights reserved.
//

#import "AppDelegate.h"
#import "ControlAcrobat.h"
#import "TableController.h"

@interface AppDelegate ()
@property (weak) IBOutlet TableController *tbl;
@property (weak) IBOutlet ControlAcrobat *acro;
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *txtOKPath;
@property (weak) IBOutlet NSTextField *txtTopSigs;
@property (weak) IBOutlet NSTextField *txtLastSigs;
- (IBAction)openOKFolder:(id)sender;
- (IBAction)processCombine:(id)sender;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

// templateの並び順に再配置
- (NSMutableArray*)reArrangeSig:(NSArray*)template realSigs:(NSMutableArray*)arReals
{
    NSMutableArray* ret = [NSMutableArray array];
    for (int i = 0; i < template.count; i++) {
        NSString *curSig = template[i];
        for (NSString *sig in arReals) {
            if (EQ_STR(sig, curSig)) {
                [ret addObject:curSig];
            }
        }
    }
    return ret;
}

- (void)moveFolder:(NSString*)path folName:(NSString*)name
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *ngPath = [_txtOKPath.stringValue stringByAppendingPathComponent:name];
    if (![fm fileExistsAtPath:ngPath]) {
        [fm createDirectoryAtPath:ngPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *folName = [path lastPathComponent];
    folName = [ngPath stringByAppendingPathComponent:folName];
    [fm copyItemAtPath:path toPath:folName error:nil];
    [fm trashItemAtURL:[NSURL fileURLWithPath:path] resultingItemURL:nil error:nil];
}

- (void)moveOKFolder:(NSString*)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *okPath = [_txtOKPath.stringValue stringByAppendingPathComponent:@"すみ"];
    if (![fm fileExistsAtPath:okPath]) {
        [fm createDirectoryAtPath:okPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *folName = [path lastPathComponent];
    folName = [okPath stringByAppendingPathComponent:folName];
    [fm copyItemAtPath:path toPath:folName error:nil];
    [fm trashItemAtURL:[NSURL fileURLWithPath:path] resultingItemURL:nil error:nil];
}

- (NSArray*)getRearrangedFileList:(NSArray*)curFilePaths
{
    NSMutableArray *arInfos = [NSMutableArray array];
    BOOL isError = NO;
    NSMutableString *erMessage = [NSMutableString string];
    NSString *curDir = [KZLibs getCurDir:curFilePaths[0]];
    for (NSString *file in curFilePaths) {
        NSString* strRet = [_acro openAndGetLabel:file];
        if ([KZLibs isExistString:strRet searchStr:@"ラベル："]) {
            isError = YES;
            [erMessage appendFormat:@"---- ファイルのラベルとページ数が合ってません(%@)\n%@",[file lastPathComponent], strRet];
            continue;
        }
        NSArray *arRange = [strRet componentsSeparatedByString:@"-"];
        NSMutableDictionary *pdfInfo = [NSMutableDictionary dictionary];
        [pdfInfo setObject:[file lastPathComponent]
                    forKey:@"fileName"];
        [pdfInfo setObject:[NSNumber numberWithUnsignedInteger:[arRange[0] intValue]]
                    forKey:@"firstPage"];
        [pdfInfo setObject:[NSNumber numberWithUnsignedInteger:[arRange[1] intValue]]
                    forKey:@"lastPage"];
        [arInfos addObject:pdfInfo];
    }
    if (isError) {
        [erMessage writeToFile:[curDir stringByAppendingPathComponent:@"err.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [_acro closeAllDoc];
        [self moveFolder:curDir folName:@"NG(白ページ)もれ"];
        return nil;
    }
    
    NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"firstPage" ascending:YES];
    [arInfos sortUsingDescriptors:@[desc]];
    NSMutableArray *retFiles = [NSMutableArray array];
    int beforePage = 0;
    for (int i = 0; i < arInfos.count; i++) {
        int fs = [arInfos[i][@"firstPage"] intValue];
        int ls = [arInfos[i][@"lastPage"] intValue];
        if (beforePage == 0) {
            beforePage = ls;
        }
        else {
            if (beforePage + 1 != fs) {
                isError = YES;
                [erMessage appendFormat:@"---- 前ジョブの終了と次ジョブの開始ページが合ってません\n前：%@　後：%@\n",arInfos[i-1][@"fileName"], arInfos[i][@"fileName"]];
                beforePage = ls;
                continue;
            }
            beforePage = ls;
        }
        [retFiles addObject:arInfos[i][@"fileName"]];
    }
    if (isError) {
        [erMessage writeToFile:[curDir stringByAppendingPathComponent:@"err.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [_acro closeAllDoc];
        [self moveFolder:curDir folName:@"NG(白ページ)もれ"];
        return nil;
    }
    return [retFiles copy];
}

- (IBAction)openOKFolder:(id)sender
{
    NSString *fol = [KZLibs openFileDialog:@"保存フォルダを選択" multiple:NO selectFile:NO selectDir:YES][0];
    _txtOKPath.stringValue = fol;
}

- (IBAction)processCombine:(id)sender
{
    NSMutableArray *datas = _tbl.tableContent;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (!_txtOKPath.stringValue || EQ_STR(_txtOKPath.stringValue, @"")) {
        _txtOKPath.stringValue = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    }
    
    NSString *okPath = [_txtOKPath.stringValue stringByAppendingPathComponent:@"OK"];
    if (![fm fileExistsAtPath:okPath]) {
        [fm createDirectoryAtPath:okPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    for (NSMutableDictionary *row in datas) {
        NSString *folder = row[@"path"];
        NSArray *folderContents = [KZLibs getFileList:folder deep:NO onlyDir:NO onlyFile:YES isAllFullPath:YES];
        NSArray *sortedFiles = [self getRearrangedFileList:folderContents];
        if (sortedFiles == nil) {
            continue;
        }
        NSString *fName = [folder lastPathComponent];
        fName = [NSString stringWithFormat:@"%@_%@",[fName componentsSeparatedByString:@"_"][0],[fName componentsSeparatedByString:@"_"][1]];
        fName = [NSString stringWithFormat:@"%@_R_000.pdf",fName];
        NSString *savePath = [okPath stringByAppendingPathComponent:fName];
        [_acro combineAllPDF:sortedFiles savePath:savePath];
        if (![_acro checkPageCount:savePath]) {
            NSString* toP = [folder stringByAppendingPathComponent:[savePath lastPathComponent]];
            [fm moveItemAtPath:savePath toPath:toP error:nil];
            [@"---- 作成したPDFのページ数が16で割り切れません。\n" writeToFile:[folder stringByAppendingPathComponent:@"err.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            [_acro closeAllDoc];
            [self moveFolder:folder folName:@"NG(白ページ)もれ"];
            continue;
        }
        else {
            [self moveFolder:folder folName:@"すみ"];
        }
        
    }
}
@end
