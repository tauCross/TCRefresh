# TCRefresh

#### Podfile

```ruby
platform :ios, '7.0'
pod "TCRefresh"
```

#### usage
```Objective-C
#import <TCRefresh.h>

...
...
...

[self.tableView setupRefreshWithBottomAt:200 refreshBlock:^{

}];

...
...
...
[self.tableView startRefresh];
...
...
...
[self.tableView endRefresh];

```
