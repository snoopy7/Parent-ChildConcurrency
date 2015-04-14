//
//  Person.h
//  Parent-ChildConcurrencyExperiments
//
//  Created by uriae walker on 2/17/15.
//  Copyright (c) 2015 developmentnow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Person : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * age;

@end
