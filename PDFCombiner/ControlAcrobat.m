//
//  ControlAcrobat.m
//  ProjectDB
//
//  Created by uchiyama_Macmini on 2017/06/13.
//  Copyright © 2017年 uchiyama_Macmini. All rights reserved.
//

#import "ControlAcrobat.h"

@implementation ControlAcrobat

- (id) init
{
    self = [super init];
    if (self != nil) {
        
    }
    return self;
}

#pragma mark -
#pragma mark Internal Functions
- (NSAppleEventDescriptor*)executeScript:(NSString*) source
{
    NSError* err;
    NSDictionary  *asErrDic = nil;
    [source writeToURL:[NSURL fileURLWithPath:@"/tmp/test.applescript"] atomically:NO encoding:NSUTF8StringEncoding error:&err];
    NSAppleScript* as = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor* result = [as executeAndReturnError : &asErrDic ];
    if ( asErrDic ) {
        NSLog(@"%@",[asErrDic objectForKey:NSAppleScriptErrorMessage]);
        return nil;
    }
    return result;
}

#pragma mark -
#pragma mark Outer Functions
- (NSString*) openAndGetLabel:(NSString*)file
{
    NSString *ass = [NSString stringWithFormat:@""
                     "with timeout of (1 * 60 * 60) seconds\n"
                     "set openDoc to \"%@\" as POSIX file\n"
                     "tell application \"Adobe Acrobat\"\n"
                     "  set show splash at startup to false\n"
                     "  open openDoc with invisible\n"
                     "  set tmp to AppleScript's text item delimiters\n"
                     "  set AppleScript's text item delimiters to \":\"\n"
                     "  set masterDocument to last text item of (openDoc as string)\n"
                     "  set actualPageCount to (count of pages of document masterDocument) as integer\n"
                     "  set topPage to (label text of (item 1 of pages of document masterDocument))\n"
                     "  set topPage to last text item of (topPage as string)\n"
                     "  set lastPage to (label text of (item actualPageCount of pages of document masterDocument))\n"
                     "  set lastPage to last text item of (lastPage as string)\n"
                     "  set pageCount to (lastPage as integer - topPage as integer) + 1 as integer\n"
                     "  if actualPageCount is not equal to pageCount then\n"
                     "    return \"\\t　ラベル：P\" & (topPage as string) & \"-\" & (lastPage as string) & \"\\n\\tページ数：\" & (pageCount as string)\n"
                     "  end if\n"
                     "end tell\n"
                     "end timeout\n"
                     "return (topPage as string) & \"-\" & (lastPage as string)\n"
                     ,file];
    NSAppleEventDescriptor* result = [self executeScript:ass];
    NSData *data = [result data];
    
    NSString *retVal = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    retVal = [retVal stringByReplacingOccurrencesOfString:@"\0" withString:@""];

    return retVal;
}

- (BOOL)combineAllPDF:(NSArray*)arFileList savePath:(NSString*)savePath
{
    NSMutableString *strFileList = [NSMutableString string];
    for (int i = 0; i < arFileList.count; i++) {
        NSString *path = arFileList[i];
        NSString *asPath = (i == arFileList.count - 1)? [NSString stringWithFormat:@"\"%@\"", path] : [NSString stringWithFormat:@"\"%@\",", path];
        [strFileList appendString:asPath];
    }
    NSString *ass = [NSString stringWithFormat:@""
                     "with timeout of (1 * 60 * 60) seconds\n"
                     "set openDocs to {%@} as list\n"
                     "set savePath to (POSIX path of \"%@\")\n"
                     "tell application \"Adobe Acrobat\"\n"
                     "  set show splash at startup to false\n"
                     "  set firstFile to item 1 of openDocs\n"
                     "  repeat with i from 2 to count of openDocs\n"
                     "      set nextFile to (item i of openDocs)\n"
                     "      set PageNum to count of «class cpag» of document nextFile\n"
                     "      insert pages document firstFile after -1 from document nextFile starting with 1 number of pages PageNum\n"
                     "      close document nextFile without saving\n"
                     "  end repeat\n"
                     "  save document firstFile to savePath\n"
                     "  close all docs without saving\n"
                     "end tell\n"
                     "end timeout\n"
                     ,[strFileList copy], savePath];
    [[self executeScript:ass] stringValue];
    return YES;
}

- (BOOL)checkPageCount:(NSString*)pdfFile
{
    NSUInteger count = [KZLibs getPDFPageCount:pdfFile];
    return (count % 16 == 0) ? YES : NO;
    
}

- (void)closeAllDoc
{
    NSString *ass = @""
                     "with timeout of (1 * 60 * 60) seconds\n"
                     "tell application \"Adobe Acrobat\"\n"
                     "  close all docs without saving\n"
                     "end tell\n"
                     "end timeout\n";
    [self executeScript:ass];
}
@end
