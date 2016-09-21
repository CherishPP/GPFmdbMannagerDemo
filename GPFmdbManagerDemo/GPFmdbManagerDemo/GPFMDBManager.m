//
//  GPFMDBManager.m
//  LittleLove
//
//  Created by 高盼盼 on 16/9/20.
//  Copyright © 2016年 高盼盼. All rights reserved.
//

#import "GPFMDBManager.h"
#import <objc/runtime.h>

@interface GPFMDBManager ()
{
//    FMDatabase * _database;
    FMDatabaseQueue * _databaseQueue;
}

@end

@implementation GPFMDBManager

+ (instancetype)fmdbManager{
    static GPFMDBManager * manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSLog(@"数据库路径：%@",[self databasePath]);
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:[self databasePath]];
    }
    return self;
}

- (NSString *)databasePath{
    NSString * documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return [documentPath stringByAppendingString:@"llData.db"];
}

//--------------------------
/**
 *  插入数据
 */
- (void)insertObjectToDataBaseWithObject:(id)object{
    //表名
    NSString * tbName = NSStringFromClass([object class]);
    //如果表不存在
    if (![self isExistTableInDatabaseWithTableName:tbName]) {
        //创建表
        [self createTableWithObject:object];
    }
    //插入数据
    NSMutableString *sql = [NSMutableString stringWithFormat:@"insert into %@ (",tbName];
    
    //values (xx)
    NSMutableString *valueString = [NSMutableString stringWithString:@" values ("];
    
    //获取所有的属性
    NSArray *properties = [self propertiesFromClass:[object class]];
    
    //遍历属性
    for (int i = 0; i < properties.count; i++)
    {
        if (i == properties.count - 1)
        {
            [sql appendFormat:@"%@)",properties[i]];
            [valueString appendFormat:@"'%@')",[object valueForKey:properties[i]]];
        }
        else
        {
            [sql appendFormat:@"%@,",properties[i]];
            [valueString appendFormat:@"'%@',",[object valueForKey:properties[i]]];
        }
    }
    
    [sql appendString:valueString];
    
    [_databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * result = [db executeQuery:sql];
        //关闭数据库
        [result close];
    }];

}
/**
 *  判断指定表是否存在
 *
 *  @param tablename <#tablename description#>
 *
 *  @return <#return value description#>
 */
- (BOOL)isExistTableInDatabaseWithTableName:(NSString *)tablename
{
    //sqlite_master是系统表
    NSString *sql = @"select name from sqlite_master where type='table' and name=?";
    //查询
    __block FMResultSet *results;
    [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        results = [db executeQuery:sql,tablename];
    }];
    return results.next;
}
/**
 *  根据模型创建表
 *
 *  @param object <#object description#>
 *
 *  @return <#return value description#>
 */
- (void)createTableWithObject:(id)object
{
    //表名
    NSString *tbName = NSStringFromClass([object class]);
    
    NSMutableString *sql = [NSMutableString stringWithFormat:@"create table if not exists %@ (id integer primary key autoincrement",tbName];
    
    //获取字段名字
    NSArray *properties = [self propertiesFromClass:[object class]];
    
    for (NSString *property in properties)
    {
        [sql appendFormat:@",%@ text",property];
    }
    
    [sql appendString:@")"];
    
    //    NSLog(@"%@",sql);
    
    //执行sql语句
    [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeQuery:sql];
    }];
    
}

/**
 *  返回指定类的所有属性
 *
 *  @param cls <#cls description#>
 *
 *  @return <#return value description#>
 */
- (NSArray *)propertiesFromClass:(Class)cls
{
    //保存所有的属性名字
    NSMutableArray *array = [NSMutableArray array];
    
    //属性个数
    unsigned int outCount;
    //获取所有的属性    copy,retain,create都需要手动释放
    objc_property_t *properties = class_copyPropertyList(cls, &outCount);
    
    
    for (int i = 0; i < outCount; i++)
    {
        //每个属性的结构体
        objc_property_t property = properties[i];
        //获取属性名字
        const char *name = property_getName(property);
        
        [array addObject:[NSString stringWithUTF8String:name]];
    }
    
    //释放资源
    free(properties);
    
    return array;
}

//-----------------------
/**
 *  查询所有的数据
 *
 *  @param cls <#cls description#>
 *
 *  @return <#return value description#>
 */

- (NSArray *)queryAllObjectsFromDataBaseWithClass:(Class)cls{
    //保存数据模型
    NSMutableArray * objects = [NSMutableArray array];
    NSString *sql = [NSString stringWithFormat:@"select * from %@",NSStringFromClass(cls)];
    __block FMResultSet *results;
    [_databaseQueue inDatabase:^(FMDatabase *db) {
        results = [db executeQuery:sql];
    }];
    
    //获取属性
    NSArray *properties = [self propertiesFromClass:cls];
    
    while (results.next)
    {
        id obj = [[cls alloc] init];
        
        //遍历所有属性通过KVC赋值
        for (NSString *property in properties)
        {
            [obj setValue:[results stringForColumn:property] forKey:property];
        }
        
        //添加到数组里面
        [objects addObject:obj];
    }
    
    //关闭数据库
    [results close];
    
    return objects;
}
//---------------------------
/**
 *  删除指定表的数据
 *
 *  @return <#return value description#>
 */
- (BOOL)deleteAllObjectFromDatabaseWithClass:(Class)cls
{
    
    NSString *sql = [NSString stringWithFormat:@"delete from %@",NSStringFromClass(cls)];
    
    //执行sql
    __block BOOL isOk;
    [_databaseQueue inDatabase:^(FMDatabase *db) {
        isOk = [db executeUpdate:sql];
        [db close];
    }];
    return isOk;
}
//---------------------------
/**
 *  更新某表的数据
 */
- (void)updateObjectFromDatabaseWithClass:(Class)cls params:(NSArray *)params{
    
    
}

@end
