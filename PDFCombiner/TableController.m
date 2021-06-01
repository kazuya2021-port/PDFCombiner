//
//  TableController.m
//  PDFCombiner
//
//  Created by uchiyama_Macmini on 2019/06/07.
//  Copyright © 2019年 uchiyama_Macmini. All rights reserved.
//

#import "TableController.h"

@interface TableController () <NSControlTextEditingDelegate, NSTableViewDataSource, NSTableViewDelegate, NSPathControlDelegate, NSTextFieldDelegate>
@property (nonatomic, strong) NSArray *descriptors;
@end

@implementation TableController

static NSString* NSTableRowType = @"table.row";

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _tableContent = [NSMutableArray array];
    _descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"folderName" ascending:YES selector:@selector(compare:)]];
    return self;
}

- (void)awakeFromNib
{
    [_tableView registerForDraggedTypes:@[NSTableRowType,NSFilenamesPboardType]];
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (IBAction)clearList:(id)sender
{
    [_tableContent removeAllObjects];
    [_tableView reloadData];
}

#pragma mark -
#pragma mark DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _tableContent.count;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSData *indexSetWithData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
    [item setData:indexSetWithData forType:NSTableRowType];
    [pboard writeObjects:@[item]];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    NSArray *theDatas = [_tableContent copy];
    
    if (row > theDatas.count || row < 0) {
        return NSDragOperationNone;
    }
    
    if (!info.draggingSource) {
        return NSDragOperationCopy;
    }
    else if (info.draggingSource == self) {
        return NSDragOperationNone;
    }
    else if (info.draggingSource == tableView) {
        [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
        return NSDragOperationMove;
    }
    return NSDragOperationCopy;
}

- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *data = _tableContent[row];
    NSString *identifier = tableColumn.identifier;
    NSTableCellView *cell = [tableView makeViewWithIdentifier:identifier owner:self];
    cell.textField.editable = YES;
    
    cell.objectValue = data[identifier];
    cell.textField.stringValue = data[identifier];
    cell.identifier = [identifier stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)row]];
    cell.textField.delegate = self;
    cell.textField.cell.representedObject = @{@"Col" : identifier,
                                              @"Row" : [NSNumber numberWithInteger:row]};
    return cell;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    
    NSTableView *dragSource = info.draggingSource;
    if (dragSource != NULL) {
        if (![KZLibs isEqual:dragSource.identifier compare:tableView.identifier]) {
            return NO;
        }
    }
    NSPasteboard *pb = info.draggingPasteboard;
    NSArray *arTypes = pb.types;
    
    NSMutableArray *theDatas = _tableContent;
    
    
    for (NSString *type in arTypes) {
        if ([KZLibs isEqual:type compare:NSFilenamesPboardType]) {
            // File Drop To Table View
            NSData *data = [pb dataForType:NSFilenamesPboardType];
            NSError *error;
            NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
            NSArray *theFiles = [NSPropertyListSerialization
                                 propertyListWithData:data
                                 options:(NSPropertyListReadOptions)NSPropertyListImmutable
                                 format:&format
                                 error:&error];
            if (error) {
                LogF(@"get file property error : %@", error.description);
                break;
            }
            if (!theFiles) {
                Log(@"get file property error");
                break;
            }
            
            for (NSUInteger i = 0; i < theFiles.count; i++) {
                NSMutableDictionary *mud = [NSMutableDictionary dictionary];
                NSString *folName = [KZLibs getFileName:theFiles[i]];
                [mud setObject:folName forKey:@"folderName"];
                [mud setObject:theFiles[i] forKey:@"path"];
                [_tableContent addObject:mud];
            }
        }
        else if ([KZLibs isEqual:type compare:NSTableRowType]) {
            // Row Drop To Table View
            // only Daiwari Table!!
            
            NSData *data = [pb dataForType:NSTableRowType];
            NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            
            
            __block NSUInteger i = 0;
            NSMutableArray *insertArray = [NSMutableArray array];
            NSMutableIndexSet *insertIndexes = [NSMutableIndexSet indexSet];
            NSInteger first = rowIndexes.firstIndex;
            
            if (row == theDatas.count) {
                // insert last
                i = theDatas.count - rowIndexes.count;
            }
            else if (row == theDatas.count - 1) {
                i = (theDatas.count - rowIndexes.count) - 1;
            }
            else if (row <= 0) {
                i = 0;
            }
            else if (row == 1) {
                i = 1;
            }
            else {
                i = (row < first)? row : row - rowIndexes.count;
            }
            
            [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                NSMutableDictionary *obj = [[NSMutableDictionary alloc] initWithDictionary:theDatas[idx]];
                [insertArray addObject:obj];
                [insertIndexes addIndex:i];
                i++;
            }];
            
            [theDatas removeObjectsInArray:[insertArray copy]];
            [theDatas insertObjects:insertArray atIndexes:[insertIndexes copy]];
            [tableView selectRowIndexes:insertIndexes byExtendingSelection:YES];
            
        }
    }
    [tableView reloadData];
    return YES;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors
{
    NSArray* newDescriptors = [tableView sortDescriptors];
    [_tableContent sortUsingDescriptors:newDescriptors];
    [tableView reloadData];
}

@end
