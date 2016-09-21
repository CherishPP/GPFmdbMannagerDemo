//
//  GPFMDBManager.h
//  LittleLove
//
//  Created by 高盼盼 on 16/9/20.
//  Copyright © 2016年 高盼盼. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

@interface GPFMDBManager : NSObject
/**
 *  单利对象
 *
 *  @return <#return value description#>
 */
+ (instancetype)fmdbManager;
/**
 *  插入数据
 *
 *  @return <#return value description#>
 */
- (void)insertObjectToDataBaseWithObject:(id)object;
/**
 *  查询数据
 */
- (NSArray *)queryAllObjectsFromDataBaseWithClass:(Class)cls;
/**
 *  删除某表的全部数据
 */
- (BOOL)deleteAllObjectFromDatabaseWithClass:(Class)cls;
/**
 *  更新某表的数据
 */
- (void)updateObjectFromDatabaseWithClass:(Class)cls params:(NSArray *)params;



@end
