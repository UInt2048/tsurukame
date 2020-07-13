// Copyright 2018 David Sansome
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "ReviewItem.h"
#import "Tsurukame-Swift.h"

@implementation ReviewItem

+ (NSArray<ReviewItem *> *)assignmentsReadyForReview:(NSArray<TKMAssignment *> *)assignments
                                          dataLoader:(DataLoader *)dataLoader
                                  localCachingClient:(LocalCachingClient *)localCachingClient {
  NSMutableArray *ret = [NSMutableArray array];
  TKMUser *userInfo = [localCachingClient getUserInfo];
  for (TKMAssignment *assignment in assignments) {
    if (![dataLoader isValidSubjectID:assignment.subjectId]) {
      continue;
    }

    if (userInfo.hasLevel && userInfo.level < assignment.level) {
      continue;
    }

    if (assignment.isReviewStage && assignment.availableAtDate.timeIntervalSinceNow < 0) {
      [ret addObject:[[ReviewItem alloc] initFromAssignment:assignment]];
    }
  }
  return ret;
}

+ (NSArray<ReviewItem *> *)assignmentsReadyForLesson:(NSArray<TKMAssignment *> *)assignments
                                          dataLoader:(DataLoader *)dataLoader
                                  localCachingClient:(LocalCachingClient *)localCachingClient {
  NSMutableArray *ret = [NSMutableArray array];
  TKMUser *userInfo = [localCachingClient getUserInfo];
  for (TKMAssignment *assignment in assignments) {
    if (![dataLoader isValidSubjectID:assignment.subjectId]) {
      continue;
    }

    if (userInfo.hasLevel && userInfo.level < assignment.level) {
      continue;
    }

    if (assignment.isLessonStage) {
      [ret addObject:[[ReviewItem alloc] initFromAssignment:assignment]];
    }
  }
  return ret;
}

- (NSUInteger)getSubjectTypeIndex:(TKMSubject_Type)type {
  for (int _i = 0; _i < Settings.lessonOrder.count; _i++) {
    TKMSubject_Type i = (TKMSubject_Type)Settings.lessonOrder[_i];
    if (i == TKMSubject_Type_GPBUnrecognizedEnumeratorValue) continue;
    if (i == type) return _i;
  }
  return Settings.lessonOrder.count + 1;  // Order anything not present after everything else
}

- (instancetype)initFromAssignment:(TKMAssignment *)assignment {
  if (self = [super init]) {
    _assignment = assignment;
    _answer = [[TKMProgress alloc] init];
    _answer.assignment = assignment;
    _answer.isLesson = assignment.isLessonStage;
  }
  return self;
}

- (BOOL)compareForLessons:(ReviewItem *)other {
  if (self.assignment.level < other.assignment.level) {
    return Settings.prioritizeCurrentLevel ? false : true;
  } else if (self.assignment.level > other.assignment.level) {
    return Settings.prioritizeCurrentLevel ? true : false;
  }

  if ([Settings.lessonOrder count]) {
    NSUInteger selfIndex = [self getSubjectTypeIndex:self.assignment.subjectType];
    NSUInteger otherIndex = [self getSubjectTypeIndex:other.assignment.subjectType];
    if (selfIndex < otherIndex) {
      return true;
    } else if (selfIndex > otherIndex) {
      return false;
    } else if (selfIndex == otherIndex && selfIndex == Settings.lessonOrder.count + 1) {
      return drand48() <= 0.5;  // Shuffle
    }
  }

  // Order by subject ID if equal sort and not shuffling
  return (self.assignment.subjectId <= other.assignment.subjectId);
}

- (void)reset {
  _answer.hasMeaningWrong = NO;
  _answer.hasReadingWrong = NO;
  _answeredMeaning = NO;
  _answeredReading = NO;
}

@end
