#import <Asterism/Asterism.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

#import "AddConsumptionViewModel.h"
#import "CaffeineHistoryManager.h"
#import "DrinkConsumption.h"
#import "HistoryCellViewModel.h"

#import "HistoryViewModel.h"

static NSString * const HistoryKey = @"History";

@interface HistoryViewModel ()
@property (readwrite, nonatomic, strong) NSArray *drinks;
@property (readwrite, nonatomic, strong) NSDictionary *clusteredDrinks;
@property (readwrite, nonatomic, strong) NSArray *sortedDateKeys;
@property (readonly, nonatomic, strong) NSDateFormatter *headerDateFormatter;
@end

@implementation HistoryViewModel

- (id)initWithCaffeineHistoryManager:(CaffeineHistoryManager *)manager {
    self = [super init];
    if (!self) return nil;

    _manager = manager;

    RAC(self, drinks) = [[[self rac_signalForSelector:@selector(refetchHistory)]
        flattenMap:^RACStream *(id value) {
            return [[manager fetchHistory] collect];
        }] doNext:^(NSArray *drinks) {
            [self persistDrinks:drinks];
        }];

    RAC(self, clusteredDrinks) = [RACObserve(self, drinks)
        map:^id(NSArray *drinks) {
            NSCalendar *calendar = [NSCalendar currentCalendar];
            return ASTGroupBy(drinks, ^id<NSCopying>(DrinkConsumption *drink) {
                NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:drink.timestamp];
                return [calendar dateFromComponents:components];
            });
        }];

    RAC(self, sortedDateKeys) = [RACObserve(self, clusteredDrinks) map:^id(NSDictionary *dict) {
        return [dict.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSDate *date1, NSDate *date2) {
            return [date1 compare:date2];
        }].reverseObjectEnumerator.allObjects;
    }];

    _headerDateFormatter = [[NSDateFormatter alloc] init];
    _headerDateFormatter.dateStyle = NSDateFormatterMediumStyle;

    self.drinks = self.cachedDrinks;

    return self;
}

#pragma mark - KVO
+ (NSSet *)keyPathsForValuesAffectingNumberOfSections {
    return [NSSet setWithObject:@keypath(HistoryViewModel.new, drinks)];
}

#pragma mark - Persistence
- (void)persistDrinks:(NSArray *)drinks {
    if (!self.drinks) { return; }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:drinks];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:data forKey:HistoryKey];
    [defaults synchronize];
}

- (NSArray *)cachedDrinks {
    NSData *data = [NSUserDefaults.standardUserDefaults objectForKey:HistoryKey];
    if (!data) return nil;

    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

#pragma mark -
- (NSArray *)drinksForDateAtIndex:(NSInteger)index {
    id key = self.sortedDateKeys[index];
    return self.clusteredDrinks[key];
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return [[self drinksForDateAtIndex:section] count];
}

- (NSInteger)numberOfSections {
    return self.sortedDateKeys.count;
}

- (NSString *)dateStringForSection:(NSInteger)section {
    NSDate *date = self.sortedDateKeys[section];
    return [self.headerDateFormatter stringFromDate:date];
}

- (DrinkConsumption *)drinkAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *drinks = [self drinksForDateAtIndex:indexPath.section];
    if (!drinks) return nil;
    if (indexPath.row >= drinks.count) return nil;

    return drinks[indexPath.row];
}

- (AddConsumptionViewModel *)editViewModelAtIndexPath:(NSIndexPath *)indexPath {
    DrinkConsumption *drink = [self drinkAtIndexPath:indexPath];
    return [[AddConsumptionViewModel alloc] initWithConsumption:drink editing:YES];
}

- (HistoryCellViewModel *)cellViewModelAtIndexPath:(NSIndexPath *)indexPath {
    DrinkConsumption *drink = [self drinkAtIndexPath:indexPath];
    return [[HistoryCellViewModel alloc] initWithConsumption:drink];
}

#pragma mark - Actions
- (RACSignal *)deleteAtIndexPath:(NSIndexPath *)indexPath {
    DrinkConsumption *drink = [self drinkAtIndexPath:indexPath];
    return [self.manager deleteDrink:drink];
}

- (RACSignal *)editDrinkAtIndexPath:(NSIndexPath *)indexPath to:(DrinkConsumption *)to {
    DrinkConsumption *from = [self drinkAtIndexPath:indexPath];
    return [self.manager editDrink:from toDrink:to];
}

#pragma mark - Noop
- (void)refetchHistory {}

@end