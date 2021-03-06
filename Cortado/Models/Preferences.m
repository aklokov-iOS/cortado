#import <Asterism/Asterism.h>

#import "Preferences.h"

@implementation Preferences

- (id)init {
    self = [super init];
    if (!self) return nil;

    _drinks = @[];

    return self;
}

- (id)initWithDrinks:(NSArray *)drinks {
    self = [super init];
    if (!self) return nil;

    _drinks = drinks ?: @[];

    return self;
}

- (instancetype)preferencesByAddingDrink:(Drink *)drink {
    NSArray *newDrinks = [self.drinks arrayByAddingObject:drink];
    return [[self.class alloc] initWithDrinks:newDrinks];
}

- (instancetype)preferencesByRemovingDrinkAtIndex:(NSUInteger)index {
    NSMutableArray *newDrinks = self.drinks.mutableCopy;
    [newDrinks removeObjectAtIndex:index];
    return [[self.class alloc] initWithDrinks:newDrinks.copy];
}

- (instancetype)preferencesByMovingDrinkAtIndex:(NSUInteger)index1 toIndex:(NSUInteger)index2 {
    if (index1 >= self.drinks.count || index2 >= self.drinks.count) return nil;

    NSMutableArray *newArray = self.drinks.mutableCopy;
    Drink *drink = self.drinks[index1];

    [newArray removeObjectAtIndex:index1];
    [newArray insertObject:drink atIndex:index2];

    return [[self.class alloc] initWithDrinks:newArray.copy];
}

- (instancetype)preferencesByReplacingDrinkAtIndex:(NSUInteger)index withDrink:(Drink *)drink {
    NSMutableArray *newArray = self.drinks.mutableCopy;
    [newArray replaceObjectAtIndex:index withObject:drink];
    return [[self.class alloc] initWithDrinks:newArray.copy];
}

@end
