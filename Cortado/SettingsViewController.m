#import <VTAcknowledgementsViewController/VTAcknowledgementsViewController.h>

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:NSBundle.mainBundle];
    return [storyboard instantiateInitialViewController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings / About";
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqualToString:@"share"]) {
        [self showShareSheet];
    } else if ([cell.reuseIdentifier isEqualToString:@"acknowledgements"]) {
        [self showAcknowledgements];
    }
}


#pragma mark - Actions

- (void)showShareSheet {
    UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[@"I'm tracking my caffeine consumption using Cortado!", [NSURL URLWithString:@"http://lazerwalker.com"]] applicationActivities:nil];

    shareController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList];

    [self.navigationController presentViewController:shareController animated:YES completion:nil];
}

- (void)showAcknowledgements {
    VTAcknowledgementsViewController *viewController = [VTAcknowledgementsViewController acknowledgementsViewController];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
