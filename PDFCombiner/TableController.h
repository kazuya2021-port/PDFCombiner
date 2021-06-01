//
//  TableController.h
//  PDFCombiner
//
//  Created by uchiyama_Macmini on 2019/06/07.
//  Copyright © 2019年 uchiyama_Macmini. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface TableController : NSObject <NSTableViewDelegate,NSTableViewDataSource>
@property (nonatomic, strong) NSMutableArray *tableContent;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
- (IBAction)clearList:(id)sender;
@end
