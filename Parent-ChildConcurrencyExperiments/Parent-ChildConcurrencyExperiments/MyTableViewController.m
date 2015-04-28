//
//  MyTableViewController.m
//  Parent-ChildConcurrencyExperiments
//
//  Created by uriae walker on 2/17/15.
//  Copyright (c) 2015 developmentnow. All rights reserved.
//

#import "MyTableViewController.h"
#import "Person.h"
#import "AppDelegate.h"
#import "HeaderTableViewCell.h"

@interface MyTableViewController ()

@property (nonatomic, strong) NSMutableArray * personArray;
@property (nonatomic, strong) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext *writerMangedObjectContext;

@end

@implementation MyTableViewController
@synthesize personArray = _personArray;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize writerMangedObjectContext = _writerMangedObjectContext;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    _personArray = [@[]mutableCopy];
    
    /**************************************************
     WRITER MOC MODEL
     **************************************************/
    
//    _writerMangedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication] delegate] writerManagedObjectContext];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _personArray.count ? _personArray.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    HeaderTableViewCell * hcell = nil;
    
    
    if (indexPath.row == 0) {
        hcell = [tableView dequeueReusableCellWithIdentifier:@"headercell" forIndexPath:indexPath];
    }else{
        
        long modelRow = indexPath.row - 1;
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        Person *tempPerson = (Person *)_personArray[modelRow];
        cell.textLabel.text = tempPerson.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",tempPerson.age];
        
    }
    
    if(cell){
        return cell;
    }else{
        return hcell;
    }

    
    return cell;
}

//bubble sort - array sorting algorithm
-(NSMutableArray *)bubbleSort:(NSMutableArray*)numArray{
    long count = numArray.count;
    NSMutableArray * numArrayTemp = [NSMutableArray arrayWithArray:numArray];
    BOOL swapped = YES;
    
    while (swapped) {
        swapped = NO;
        for(int i = 1; i < count; i++){
            if ([numArrayTemp objectAtIndex:(i - 1)] > [numArrayTemp objectAtIndex:i]) {
                [numArrayTemp exchangeObjectAtIndex:(i - 1) withObjectAtIndex:i];
                swapped = YES;
            }
        }
    }
    
    return numArrayTemp;
}


- (IBAction)startClicked:(id)sender {

    //create an unsorted array to be sorted via a bubble sort
    NSMutableArray *numArray = [@[] mutableCopy];
    
    for (int i = 0; i < 20; i++) {
        
        int num = arc4random_uniform(100);
        numArray[i] = [NSNumber numberWithInt:num];
    }
    
    /**************************************************
     SINGLE MOC MODEL
     **************************************************/

    //data load
    NSLog(@"Starting Core Data Operations");
    
    NSDate *loadStartTime = [NSDate date];
    
    for (int i = 0; i < 500000; i++) {
     
        Person* person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:_managedObjectContext];
         
        person.name = @"Boomer";

        //sort the array using the bubble sort algorithm to simulate a lengthy manipulate operation
        person.age = [[self bubbleSort:numArray] objectAtIndex: 0];
    
     
    }
    
    
    NSTimeInterval secondsLoad = [[NSDate date] timeIntervalSinceDate:loadStartTime];
    NSLog(@"%f seconds for load", secondsLoad);
    
    
    //data fetch
    NSDate *fetchStartTime = [NSDate date];
    
    NSFetchRequest *fetch = [[NSFetchRequest alloc]init];
    [fetch setEntity:[NSEntityDescription entityForName:@"Person" inManagedObjectContext:_managedObjectContext]];
    
    NSError *error0 = nil;
    
    [_personArray addObjectsFromArray:[_managedObjectContext executeFetchRequest:fetch error:&error0]];
    
    NSTimeInterval secondsFetch = [[NSDate date] timeIntervalSinceDate:fetchStartTime];
    NSLog(@"%f seconds for fetch", secondsFetch);
    
    [self.tableView reloadData];

    
    //data write
    NSDate *writeStartTime = [NSDate date];
    
    NSError * error;
    if(![_managedObjectContext save:&error]){
     
        NSLog(@"Save Error: %@", [error localizedDescription]);
     
    }

    NSTimeInterval secondsSave = [[NSDate date] timeIntervalSinceDate:writeStartTime];
    NSLog(@"%f seconds for write", secondsSave);
    
    
    /**************************************************
     DOUBLE MOC MODEL
     **************************************************/
    
//    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//    temporaryContext.parentContext = _managedObjectContext;
//    
//    //start load
//    NSLog(@"inserting data into temporary context...");
//    
//    NSDate *loadStartTime = [NSDate date];
//    
//    [temporaryContext performBlock:^{
//        
//        NSDate *insertStart = [NSDate date];
//        
//        for (int i = 0; i < 500000; i++) {
//            
//            Person * person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:temporaryContext];
//            
//            person.name = @"Sharon";
//            person.age = [[self bubbleSort:numArray] objectAtIndex: 0];
//            
//            if(i % 5000 == 0){
//                NSError * error;
//                if(![temporaryContext save:&error]){
//                    
//                    NSLog(@"Save Error: %@", [error localizedDescription]);
//                    
//                }
//            }
//        }
//        
//        NSTimeInterval secondsLoad = [[NSDate date] timeIntervalSinceDate:loadStartTime];
//        NSLog(@"%f seconds for load", secondsLoad);
//        
//        
//        NSLog(@"pushing to parent context (main context)");
//        
//        //push to parent
//        NSDate *pushStart = [NSDate date];
//        
//        NSError * error;
//        
//        if(![temporaryContext save:&error]){
//            
//            NSLog(@"Save Error: %@", [error localizedDescription]);
//            
//        }
//        
//        NSTimeInterval secondsPush = [[NSDate date] timeIntervalSinceDate:pushStart];
//        NSLog(@"%f seconds to push data to parent context (main context)", secondsPush);
//        
//        //start fetch
//        NSDate *fetchStart = [NSDate date];
//        [_managedObjectContext performBlock:^{
//            
//            NSFetchRequest *fetch = [[NSFetchRequest alloc]init];
//            [fetch setEntity:[NSEntityDescription entityForName:@"Person" inManagedObjectContext:_managedObjectContext]];
//            
//            NSError *error0 = nil;
//            
//            [_personArray addObjectsFromArray:[_managedObjectContext executeFetchRequest:fetch error:&error0]];
//            
//            NSTimeInterval secondsFetch = [[NSDate date] timeIntervalSinceDate:fetchStart];
//            NSLog(@"%f seconds for fetch", secondsFetch);
//            
//            [self.tableView reloadData];
//            
//            
//            NSDate *writeStart = [NSDate date];
//            
//            NSError * error;
//            
//            if(![_managedObjectContext save:&error]){
//                
//                NSLog(@"Save Error: %@", [error localizedDescription]);
//                
//            }
//            
//            NSDate *writeEnd = [NSDate date];
//            NSTimeInterval secondsPt3 = [writeEnd timeIntervalSinceDate:writeStart];
//            NSLog(@"%f seconds for write", secondsPt3);
//            
//        }];
//    }];
    
    /**************************************************
     WRITER MOC MODEL 
     **************************************************/
    
    
//    NSManagedObjectContext * temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//    
//    temporaryContext.parentContext = _managedObjectContext;
//    
//    NSDate *loadStartTime = [NSDate date];
//    
//    [temporaryContext performBlock:^{
//        
//        NSLog(@"inserting data into temporary context...");
//        for (int i = 0; i < 500000; i++) {
//            
//            Person * person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:temporaryContext];
//            
//            person.name = @"Starbuck";
//            person.age = [[self bubbleSort:numArray] objectAtIndex: 0];
//            
//            if(i % 5000 == 0){
//                NSError * error;
//                if(![temporaryContext save:&error]){
//                    
//                    NSLog(@"Save Error: %@", [error localizedDescription]);
//                    
//                }
//                
//            }
//            
//        }
//        
//        NSTimeInterval secondsLoad = [[NSDate date] timeIntervalSinceDate:loadStartTime];
//        NSLog(@"%f seconds for load", secondsLoad);
//        
//        
//        //push to parent
//        NSLog(@"pushing to parent context (main context)");
//        
//        NSDate *pushStart = [NSDate date];
//        
//        NSError * error;
//        if(![temporaryContext save:&error]){
//            
//            NSLog(@"Save Error: %@", [error localizedDescription]);
//            
//        }
//        
//        NSTimeInterval secondsPush = [[NSDate date] timeIntervalSinceDate:pushStart];
//        NSLog(@"%f seconds to push data to parent context", secondsPush);
//        
//        
//        //start fetch
//        NSDate *fetchStart = [NSDate date];
//        [_managedObjectContext performBlock:^{
//            
//            NSFetchRequest *fetch = [[NSFetchRequest alloc]init];
//            [fetch setEntity:[NSEntityDescription entityForName:@"Person" inManagedObjectContext:_managedObjectContext]];
//            
//            NSError *error0 = nil;
//            
//            NSArray *results = [_managedObjectContext executeFetchRequest:fetch error:&error0];
//            _personArray = [results mutableCopy];
//            
//            NSTimeInterval secondsFetch = [[NSDate date] timeIntervalSinceDate:fetchStart];
//            NSLog(@"%f seconds for fetch", secondsFetch);
//            
//            [self.tableView reloadData];
//            
//            //push to parent
//            NSLog(@"pushing to parent context (writer context)");
//            
//            NSDate *writePushStart = [NSDate date];
//            NSError * error;
//            
//            if(![_managedObjectContext save:&error]){
//                
//                NSLog(@"Save Error: %@", [error localizedDescription]);
//                
//            }
//            
//            NSTimeInterval secondsWritePush = [[NSDate date] timeIntervalSinceDate:writePushStart];
//            NSLog(@"%f seconds to push data to parent context", secondsWritePush);
//            
//            NSDate *writeStart = [NSDate date];
//            
//            [_writerMangedObjectContext performBlock:^{
//                
//                //push to parent
//                NSError * error;
//                if(![_writerMangedObjectContext save:&error]){
//                    
//                    NSLog(@"Save Error: %@", [error localizedDescription]);
//                    
//                }
//                
//                NSTimeInterval secondsWrite = [[NSDate date] timeIntervalSinceDate:writeStart];
//                NSLog(@"%f seconds for write", secondsWrite);
//                
//            }];
//            
//        }];
//    }];

}





@end
