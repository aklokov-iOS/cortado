#import <ReactiveCocoa/ReactiveCocoa.h>

#import "AddConsumptionViewModel.h"
#import "DrinkSelectionViewController.h"
#import "DrinkCell.h"

#import "AddConsumptionViewController.h"

static NSString * const CellIdentifier = @"cell";

typedef NS_ENUM(NSInteger, AddConsumptionItem) {
    AddConsumptionItemDrink = 0,
    AddConsumptionItemDate,
    AddConsumptionItemCount
};

@interface AddConsumptionViewController ()
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UITextField *hiddenTextField;
@end

@implementation AddConsumptionViewController

- (id)initWithViewModel:(AddConsumptionViewModel *)viewModel {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (!self) return nil;

    self.title = (viewModel.isEditing ? @"Edit" : @"Add Caffeine");

    _viewModel = viewModel;

    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.date = self.viewModel.timestamp;
    [self.datePicker addTarget:self action:@selector(datePickerDidChange) forControlEvents:UIControlEventValueChanged];

    self.hiddenTextField = [[UITextField alloc] init];
    self.hiddenTextField.inputView = self.datePicker;
    self.hiddenTextField.hidden = YES;
    [self.view addSubview:self.hiddenTextField];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self.viewModel action:@selector(addDrink)];

    // TODO: This is bad.
    if (!self.viewModel.isEditing) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.viewModel action:@selector(cancel)];
    }

    RAC(self, navigationItem.rightBarButtonItem.enabled) = RACObserve(self, viewModel.inputValid);

    [self.tableView registerClass:DrinkCell.class forCellReuseIdentifier:NSStringFromClass(DrinkCell.class)];

    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:NSStringFromClass(UITableViewCell.class)];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [RACObserve(self, viewModel.drink) subscribeNext:^(id x) {
        [self.navigationController popToViewController:self animated:YES];
        [self.tableView reloadData];
    }];

    [RACObserve(self, viewModel.timeString) subscribeNext:^(id x) {
        [self.tableView reloadData];
    }];

    RAC(self, viewModel.timestamp) = [[self rac_signalForSelector:@selector(datePickerDidChange)] map:^id(id _) {
        return self.datePicker.date;
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.hiddenTextField resignFirstResponder];

}

#pragma mark -
- (void)showDrinkPicker {
    DrinkSelectionViewController *drinkVC = [[DrinkSelectionViewController alloc] initWithNoBeverageEnabled:NO];

    [self.navigationController pushViewController:drinkVC animated:YES];
    [[drinkVC.selectedDrinkSignal take:1]
        subscribeNext:^(Drink *drink) {
            self.viewModel.drink = drink;
        }];
}

- (void)showDatePicker {
    [self.hiddenTextField becomeFirstResponder];
}

# pragma mark - Noop for RAC
- (void)datePickerDidChange {}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return AddConsumptionItemCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    switch(indexPath.section) {
        case AddConsumptionItemDrink:
            return [self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass(DrinkCell.class) forIndexPath:indexPath];
        case AddConsumptionItemDate:
            return [self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass(UITableViewCell.class) forIndexPath:indexPath];
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section) {
        case AddConsumptionItemDrink:
            return self.viewModel.drinkTitle;
        case AddConsumptionItemDate:
            return self.viewModel.timestampTitle;
    }
    return nil;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case AddConsumptionItemDrink:
            [(DrinkCell *)cell setViewModel:self.viewModel.drinkCellViewModel];
            break;
        case AddConsumptionItemDate:
            cell.textLabel.text = self.viewModel.timeString;
            break;
    }

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch(indexPath.section) {
        case AddConsumptionItemDrink:
            [self showDrinkPicker];
            break;
        case AddConsumptionItemDate:
            [self showDatePicker];
            break;
    }
}

@end