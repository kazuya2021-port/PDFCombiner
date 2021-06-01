//
//  ControlAcrobat.h
//  ProjectDB
//
//  Created by uchiyama_Macmini on 2017/06/13.
//  Copyright © 2017年 uchiyama_Macmini. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ControlAcrobat : NSObject
- (NSString*)openAndGetLabel:(NSString*)file;
- (BOOL)combineAllPDF:(NSArray*)arFileList savePath:(NSString*)savePath;
- (void)closeAllDoc;
- (BOOL)checkPageCount:(NSString*)pdfFile;
@end
