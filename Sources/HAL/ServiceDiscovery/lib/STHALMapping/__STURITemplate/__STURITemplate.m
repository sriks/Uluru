//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import "__STURITemplate.h"


NSString * const __STURITemplateErrorDomain = @"__STURITemplate";


typedef id(^__STURITArrayMapBlock)(id o);

static NSArray *__STURITArrayByMappingArray(NSArray *array, __STURITArrayMapBlock block) {
    NSUInteger const count = array.count;
    id values[count];
    memset(values, 0, sizeof(values));
    NSUInteger i = 0;
    for (id o in array) {
        id v = block(o);
        if (v) {
            values[i++] = v;
        }
    }
    return [[NSArray alloc] initWithObjects:values count:i];
}


static NSCharacterSet *__STURITemplateScannerHexCharacterSet = nil;
static NSCharacterSet *__STURITemplateScannerInvertedLiteralComponentCharacterSet = nil;
static NSCharacterSet *__STURITemplateScannerOperatorCharacterSet = nil;
static NSCharacterSet *__STURITemplateScannerInvertedVariableNameCharacterSet = nil;
static NSCharacterSet *__STURITemplateScannerInvertedVariableNameMinusDotCharacterSet = nil;


__attribute__((constructor))
static void __STURITemplateScannerInit(void) {
    __STURITemplateScannerHexCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];

    {
        NSMutableCharacterSet *cs = [[[NSCharacterSet illegalCharacterSet] invertedSet] mutableCopy];
        [cs formIntersectionWithCharacterSet:[[NSCharacterSet controlCharacterSet] invertedSet]];
        [cs formIntersectionWithCharacterSet:[[NSCharacterSet characterSetWithCharactersInString:@" \"'%<>\\^`{|}"] invertedSet]];
        __STURITemplateScannerInvertedLiteralComponentCharacterSet = cs.invertedSet;
    }

    __STURITemplateScannerOperatorCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"+#./;?&=,!@|"];

    {
        NSMutableCharacterSet *cs = [[NSMutableCharacterSet alloc] init];
        [cs addCharactersInString:@"abcdefghijklmnopqrstuvwxyz"];
        [cs addCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
        [cs addCharactersInString:@"0123456789"];
        [cs addCharactersInString:@"_%"];
        __STURITemplateScannerInvertedVariableNameMinusDotCharacterSet = cs.invertedSet;

        [cs addCharactersInString:@"."];
        __STURITemplateScannerInvertedVariableNameCharacterSet = cs.invertedSet;
    }
}


@protocol __STURITemplateComponent <NSObject>
@property (nonatomic,copy,readonly) NSArray *variableNames;
- (NSString *)stringWithVariables:(NSDictionary *)variables;
- (NSString *)templateRepresentation;
@end
@interface __STURITemplateLiteralComponent : NSObject<__STURITemplateComponent>
- (id)initWithString:(NSString *)string;
@end
@interface __STURITemplateVariableComponent : NSObject
- (id)initWithVariables:(NSArray *)variables __attribute__((objc_designated_initializer));
@end
@interface __STURITemplateSimpleComponent : __STURITemplateVariableComponent<__STURITemplateComponent>
@end
@interface __STURITemplateReservedCharacterComponent : __STURITemplateVariableComponent<__STURITemplateComponent>
@end
@interface __STURITemplateFragmentComponent : __STURITemplateVariableComponent<__STURITemplateComponent>
@end
@interface __STURITemplatePathSegmentComponent : __STURITemplateVariableComponent<__STURITemplateComponent>
@end
@interface __STURITemplatePathExtensionComponent : __STURITemplateVariableComponent<__STURITemplateComponent>
@end
@interface __STURITemplateQueryComponent : __STURITemplateVariableComponent<__STURITemplateComponent>
@end
@interface __STURITemplateQueryContinuationComponent : __STURITemplateVariableComponent<__STURITemplateComponent>
@end
@interface __STURITemplatePathParameterComponent : __STURITemplateVariableComponent<__STURITemplateComponent>
@end


typedef NS_ENUM(NSInteger, __STURITemplateEscapingStyle) {
    __STURITemplateEscapingStyleU,
    __STURITemplateEscapingStyleUR,
};
static NSString *__STURITemplateStringByAddingPercentEscapes(NSString *string, __STURITemplateEscapingStyle style) {
    switch (style) {
        case __STURITemplateEscapingStyleU: {
            NSString *unreserved = @"-._~/?";
            NSMutableCharacterSet *allowed = [NSMutableCharacterSet alphanumericCharacterSet];
            [allowed addCharactersInString:unreserved];
            return [string stringByAddingPercentEncodingWithAllowedCharacters:allowed];
        }
        case __STURITemplateEscapingStyleUR:
            return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
}


@interface __STURITemplateComponentVariable : NSObject
- (id)initWithName:(NSString *)name;
@property (nonatomic,copy,readonly) NSString *name;
- (NSString *)stringWithValue:(id)value encodingStyle:(__STURITemplateEscapingStyle)encodingStyle;
- (NSString *)templateRepresentation;
@end

@interface __STURITemplateComponentTruncatedVariable : __STURITemplateComponentVariable
- (id)initWithName:(NSString *)name length:(NSUInteger)length;
- (NSString *)templateRepresentation;
@end

@interface __STURITemplateComponentExplodedVariable : __STURITemplateComponentVariable
- (NSString *)templateRepresentation;
@end


@interface __STURITemplateScanner : NSObject
- (instancetype)initWithString:(NSString *)string __attribute__((objc_designated_initializer));
- (BOOL)scanString:(NSString *)string intoString:(NSString * __autoreleasing *)result;
- (BOOL)scanCharactersFromSet:(NSCharacterSet *)set intoString:(NSString **)result;
- (BOOL)scanUpToString:(NSString *)string intoString:(NSString * __autoreleasing *)result;
- (BOOL)scanUpToCharactersFromSet:(NSCharacterSet *)set intoString:(NSString * __autoreleasing *)result;
@property (nonatomic,assign,getter=isAtEnd,readonly) BOOL atEnd;
- (BOOL)sturit_scanTemplateComponent:(id<__STURITemplateComponent> __autoreleasing *)component;
@end
@implementation __STURITemplateScanner {
@private
    NSScanner *_scanner;
}

-(instancetype)init {
    return [self initWithString:nil];
}

- (instancetype)initWithString:(NSString *)string {
    NSScanner * const scanner = [[NSScanner alloc] initWithString:string];
    if (!scanner) {
        return nil;
    }
    scanner.charactersToBeSkipped = nil;
    if ((self = [super init])) {
        _scanner = scanner;
    }
    return self;
}
- (BOOL)scanString:(NSString *)string intoString:(NSString * __autoreleasing *)result {
    return [_scanner scanString:string intoString:result];
}
- (BOOL)scanCharactersFromSet:(NSCharacterSet *)set intoString:(NSString **)result {
    return [_scanner scanCharactersFromSet:set intoString:result];
}
- (BOOL)scanUpToString:(NSString *)string intoString:(NSString * __autoreleasing *)result {
    return [_scanner scanUpToString:string intoString:result];
}
- (BOOL)scanUpToCharactersFromSet:(NSCharacterSet *)set intoString:(NSString * __autoreleasing *)result {
    return [_scanner scanUpToCharactersFromSet:set intoString:result];
}
- (BOOL)isAtEnd {
    return [_scanner isAtEnd];
}
- (NSString *)sturit_peekStringUpToLength:(NSUInteger)length {
    NSString * const string = _scanner.string;
    NSUInteger const scanLocation = _scanner.scanLocation;

    NSRange range = (NSRange){
        .location = scanLocation,
    };
    range.length = MIN(length, string.length - range.location);
    return [string substringWithRange:range];
}
- (BOOL)sturit_scanPercentEncoded:(NSString * __autoreleasing *)result {
    NSUInteger const scanLocation = _scanner.scanLocation;

    NSMutableString * const string = @"%".mutableCopy;

    if (![_scanner scanString:@"%" intoString:NULL]) {
        [_scanner setScanLocation:scanLocation];
        return NO;
    }

    NSString * const candidateString = [self sturit_peekStringUpToLength:2];
    if (candidateString.length != 2) {
        [_scanner setScanLocation:scanLocation];
        return NO;
    }
    unichar candidateCharacters[2] = { 0 };
    [candidateString getCharacters:candidateCharacters range:(NSRange){ .length = 2 }];

    if (![__STURITemplateScannerHexCharacterSet characterIsMember:candidateCharacters[0]]) {
        [_scanner setScanLocation:scanLocation];
        return NO;
    }
    if (![__STURITemplateScannerHexCharacterSet characterIsMember:candidateCharacters[1]]) {
        [_scanner setScanLocation:scanLocation];
        return NO;
    }

    _scanner.scanLocation += candidateString.length;
    [string appendString:candidateString];

    if (result) {
        *result = string.copy;
    }
    return YES;
}
- (BOOL)sturit_scanLiteralComponent:(id<__STURITemplateComponent> __autoreleasing *)result {
    NSUInteger const scanLocation = _scanner.scanLocation;

    NSMutableString * const string = [NSMutableString string];
    while (![_scanner isAtEnd]) {
        BOOL didSomething = NO;
        NSString *scratch = nil;

        if ([_scanner scanUpToCharactersFromSet:__STURITemplateScannerInvertedLiteralComponentCharacterSet intoString:&scratch]) {
            [string appendString:scratch];
            didSomething = YES;
        } else if ([self sturit_scanPercentEncoded:&scratch]) {
            [string appendString:scratch];
            didSomething = YES;
        }

        if (!didSomething) {
            break;
        }
    }

    if (!string.length) {
        [_scanner setScanLocation:scanLocation];
        return NO;
    }

    __STURITemplateLiteralComponent * const literalComponent = [[__STURITemplateLiteralComponent alloc] initWithString:string];
    if (!literalComponent) {
        [_scanner setScanLocation:scanLocation];
        return NO;
    }

    if (result) {
        *result = literalComponent;
    }
    return YES;
}
- (BOOL)sturit_scanVariableName:(NSString * __autoreleasing *)result {
    NSUInteger const scanLocation = _scanner.scanLocation;

    NSMutableString * const string = [[NSMutableString alloc] init];

    {
        NSString *scratch = nil;
        if ([_scanner scanUpToCharactersFromSet:__STURITemplateScannerInvertedVariableNameMinusDotCharacterSet intoString:&scratch]) {
            [string appendString:scratch];
        }
    }
    if (string.length == 0) {
        [_scanner setScanLocation:scanLocation];
        return NO;
    }

    {
        NSString *scratch = nil;
        if ([_scanner scanUpToCharactersFromSet:__STURITemplateScannerInvertedVariableNameCharacterSet intoString:&scratch]) {
            [string appendString:scratch];
        }
    }

    if (result) {
        *result = string.copy;
    }
    return YES;
}
- (BOOL)sturit_scanVariableSpecification:(__STURITemplateComponentVariable * __autoreleasing *)result {
    NSUInteger const scanLocation = _scanner.scanLocation;

    NSString *name = nil;
    if (![self sturit_scanVariableName:&name]) {
        [_scanner setScanLocation:scanLocation];
        return NO;
    }

    long long prefixLength = 0;
    if ([_scanner scanString:@":" intoString:NULL]) {
        if (![_scanner scanLongLong:&prefixLength]) {
            [_scanner setScanLocation:scanLocation];
            return NO;
        }
        if (prefixLength < 0 || prefixLength >= 10000) {
            [_scanner setScanLocation:scanLocation];
            return NO;
        }
        __STURITemplateComponentVariable * const variable = [[__STURITemplateComponentTruncatedVariable alloc] initWithName:name length:(NSUInteger)prefixLength];
        if (result) {
            *result = variable;
        }
        return YES;
    }
    if ([_scanner scanString:@"*" intoString:NULL]) {
        __STURITemplateComponentVariable * const variable = [[__STURITemplateComponentExplodedVariable alloc] initWithName:name];
        if (result) {
            *result = variable;
        }
        return YES;
    }

    __STURITemplateComponentVariable * const variable = [[__STURITemplateComponentVariable alloc] initWithName:name];
    if (result) {
        *result = variable;
    }

    return YES;
}
- (BOOL)sturit_scanVariableComponent:(id<__STURITemplateComponent> __autoreleasing *)result {
    NSUInteger const scanLocation = _scanner.scanLocation;

    if (![_scanner scanString:@"{" intoString:NULL]) {
        [_scanner setScanLocation:scanLocation];
        return NO;
    }

    NSString *operator = nil;
    {
        NSString * const candidateOperator = [self sturit_peekStringUpToLength:1];
        if (candidateOperator.length == 1 && [__STURITemplateScannerOperatorCharacterSet characterIsMember:[candidateOperator characterAtIndex:0]]) {
            _scanner.scanLocation += 1;
            operator = candidateOperator;
        }
    }

    NSMutableArray * const variables = [[NSMutableArray alloc] init];
    while (1) {
        __STURITemplateComponentVariable *variable = nil;
        if (![self sturit_scanVariableSpecification:&variable]) {
            [_scanner setScanLocation:scanLocation];
            return NO;
        }
        [variables addObject:variable];
        if (![_scanner scanString:@"," intoString:NULL]) {
            break;
        }
    }

    if (![_scanner scanString:@"}" intoString:NULL]) {
        [_scanner setScanLocation:scanLocation];
        return NO;
    }

    id<__STURITemplateComponent> component = nil;
    if (operator.length > 0) {
        switch ([operator characterAtIndex:0]) {
            case '+':
                component = [[__STURITemplateReservedCharacterComponent alloc] initWithVariables:variables];
                break;
            case '#':
                component = [[__STURITemplateFragmentComponent alloc] initWithVariables:variables];
                break;
            case '.':
                component = [[__STURITemplatePathExtensionComponent alloc] initWithVariables:variables];
                break;
            case '/':
                component = [[__STURITemplatePathSegmentComponent alloc] initWithVariables:variables];
                break;
            case ';':
                component = [[__STURITemplatePathParameterComponent alloc] initWithVariables:variables];
                break;
            case '?':
                component = [[__STURITemplateQueryComponent alloc] initWithVariables:variables];
                break;
            case '&':
                component = [[__STURITemplateQueryContinuationComponent alloc] initWithVariables:variables];
                break;
        }
        if (!component) {
            [_scanner setScanLocation:scanLocation];
            return NO;
        }
    }

    if (!component) {
        component = [[__STURITemplateSimpleComponent alloc] initWithVariables:variables];
    }

    if (!component) {
        [_scanner setScanLocation:scanLocation];
        return NO;
    }

    if (result) {
        *result = component;
    }
    return YES;
}
- (BOOL)sturit_scanTemplateComponent:(id<__STURITemplateComponent> __autoreleasing *)result {
    NSUInteger const scanLocation = _scanner.scanLocation;

    if ([self sturit_scanVariableComponent:result]) {
        return YES;
    }

    if ([self sturit_scanLiteralComponent:result]) {
        return YES;
    }

    [_scanner setScanLocation:scanLocation];
    return NO;
}
@end


@implementation __STURITemplateLiteralComponent {
@private
    NSString *_string;
}
- (id)init {
    return [self initWithString:nil];
}
- (id)initWithString:(NSString *)string {
    if ((self = [super init])) {
        _string = string.copy;
    }
    return self;
}
- (NSArray *)variableNames {
    return @[];
}
- (NSString *)stringWithVariables:(NSDictionary *)variables {
    return _string;
}
- (NSString *)templateRepresentation {
    return _string;
}
@end


typedef NS_ENUM(NSInteger, __STURITemplateVariableComponentPairStyle) {
    __STURITemplateVariableComponentPairStyleNone,
    __STURITemplateVariableComponentPairStyleElidedEquals,
    __STURITemplateVariableComponentPairStyleTrailingEquals,
};

@implementation __STURITemplateVariableComponent {
@protected
    NSArray *_variables;
    NSArray *_variableNames;
}
- (id)init {
    return [self initWithVariables:nil];
}
- (id)initWithVariables:(NSArray *)variables {
    if ((self = [super init])) {
        _variables = variables;
        _variableNames = [_variables valueForKey:@"name"];
    }
    return self;
}
- (NSArray *)variableNames {
    return _variableNames;
}
- (NSString *)stringWithVariables:(NSDictionary *)variables prefix:(NSString *)prefix separator:(NSString *)separator asPair:(__STURITemplateVariableComponentPairStyle)asPair encodingStyle:(__STURITemplateEscapingStyle)encodingStyle {
    NSMutableArray * const values = [[NSMutableArray alloc] initWithCapacity:_variables.count];
    for (__STURITemplateComponentVariable *variable in _variables) {
        id const value = variables[variable.name];
        if (value) {
            NSString * const string = [variable stringWithValue:value encodingStyle:encodingStyle];
            if (!string) {
                return nil;
            }
            NSMutableString *value = [NSMutableString string];
            switch (asPair) {
                case __STURITemplateVariableComponentPairStyleNone: {
                    if (string.length) {
                        [value appendString:string];
                    }
                } break;
                case __STURITemplateVariableComponentPairStyleElidedEquals: {
                    [value appendString:variable.name];
                    if (string.length) {
                        [value appendFormat:@"=%@", string];
                    }
                } break;
                case __STURITemplateVariableComponentPairStyleTrailingEquals: {
                    [value appendFormat:@"%@=", variable.name];
                    if (string.length) {
                        [value appendString:string];
                    }
                } break;
            }
            [values addObject:value];
        }
    }
    NSString *string = [values componentsJoinedByString:separator];
    if (string.length) {
        string = [(prefix ?: @"") stringByAppendingString:string];
    }
    return string;
}
- (NSString *)templateRepresentation {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}
- (NSString *)templateRepresentationWithPrefix:(NSString *)prefix {
    NSString * const variablesTemplateRepresentation = [[_variables valueForKey:@"templateRepresentation"] componentsJoinedByString:@","];
    return [NSString stringWithFormat:@"{%@%@}", prefix, variablesTemplateRepresentation];
}
@end

@implementation __STURITemplateSimpleComponent
@dynamic variableNames;
- (NSString *)stringWithVariables:(NSDictionary *)variables {
    return [super stringWithVariables:variables prefix:@"" separator:@"," asPair:__STURITemplateVariableComponentPairStyleNone encodingStyle:__STURITemplateEscapingStyleU];
}
- (NSString *)templateRepresentation {
    return [super templateRepresentationWithPrefix:@""];
}
@end

@implementation __STURITemplateReservedCharacterComponent
@dynamic variableNames;
- (NSString *)stringWithVariables:(NSDictionary *)variables {
    return [super stringWithVariables:variables prefix:@"" separator:@"," asPair:__STURITemplateVariableComponentPairStyleNone encodingStyle:__STURITemplateEscapingStyleUR];
}
- (NSString *)templateRepresentation {
    return [super templateRepresentationWithPrefix:@"+"];
}
@end

@implementation __STURITemplateFragmentComponent
@dynamic variableNames;
- (NSString *)stringWithVariables:(NSDictionary *)variables {
    return [super stringWithVariables:variables prefix:@"#" separator:@"," asPair:__STURITemplateVariableComponentPairStyleNone encodingStyle:__STURITemplateEscapingStyleUR];
}
- (NSString *)templateRepresentation {
    return [super templateRepresentationWithPrefix:@"#"];
}
@end

@implementation __STURITemplatePathSegmentComponent
@dynamic variableNames;
- (NSString *)stringWithVariables:(NSDictionary *)variables {
    return [super stringWithVariables:variables prefix:@"/" separator:@"/" asPair:__STURITemplateVariableComponentPairStyleNone encodingStyle:__STURITemplateEscapingStyleU];
}
- (NSString *)templateRepresentation {
    return [super templateRepresentationWithPrefix:@"/"];
}
@end

@implementation __STURITemplatePathExtensionComponent
@dynamic variableNames;
- (NSString *)stringWithVariables:(NSDictionary *)variables {
    return [super stringWithVariables:variables prefix:@"." separator:@"." asPair:__STURITemplateVariableComponentPairStyleNone encodingStyle:__STURITemplateEscapingStyleU];
}
- (NSString *)templateRepresentation {
    return [super templateRepresentationWithPrefix:@"."];
}
@end

@implementation __STURITemplateQueryComponent
@dynamic variableNames;
- (NSString *)stringWithVariables:(NSDictionary *)variables {
    return [super stringWithVariables:variables prefix:@"?" separator:@"&" asPair:__STURITemplateVariableComponentPairStyleTrailingEquals encodingStyle:__STURITemplateEscapingStyleU];
}
- (NSString *)templateRepresentation {
    return [super templateRepresentationWithPrefix:@"?"];
}
@end

@implementation __STURITemplateQueryContinuationComponent
@dynamic variableNames;
- (NSString *)stringWithVariables:(NSDictionary *)variables {
    return [super stringWithVariables:variables prefix:@"&" separator:@"&" asPair:__STURITemplateVariableComponentPairStyleTrailingEquals encodingStyle:__STURITemplateEscapingStyleU];
}
- (NSString *)templateRepresentation {
    return [super templateRepresentationWithPrefix:@"&"];
}
@end

@implementation __STURITemplatePathParameterComponent
@dynamic variableNames;
- (NSString *)stringWithVariables:(NSDictionary *)variables {
    return [super stringWithVariables:variables prefix:@";" separator:@";" asPair:__STURITemplateVariableComponentPairStyleElidedEquals encodingStyle:__STURITemplateEscapingStyleU];
}
- (NSString *)templateRepresentation {
    return [super templateRepresentationWithPrefix:@";"];
}
@end


@implementation __STURITemplateComponentVariable {
@private
}
- (id)init {
    return [self initWithName:nil];
}
- (id)initWithName:(NSString *)name {
    if ((self = [super init])) {
        _name = name.copy;
    }
    return self;
}
- (NSString *)stringWithValue:(id)value encodingStyle:(__STURITemplateEscapingStyle)encodingStyle {
    if (!value) {
        return nil;
    }
    if ([value isKindOfClass:[NSString class]]) {
        return __STURITemplateStringByAddingPercentEscapes(value, encodingStyle);
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return ((NSNumber *)value).stringValue;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        return [__STURITArrayByMappingArray(value, ^(id o) {
            return [self stringWithValue:o encodingStyle:encodingStyle];
        }) componentsJoinedByString:@","];
    }
    return nil;
}
- (NSString *)templateRepresentation {
    return _name;
}
@end

@implementation __STURITemplateComponentTruncatedVariable {
@private
    NSUInteger _length;
}
- (id)initWithName:(NSString *)name length:(NSUInteger)length {
    if ((self = [super initWithName:name])) {
        _length = length;
    }
    return self;
}
- (NSString *)stringWithValue:(id)value preserveCharacters:(BOOL)preserveCharacters {
    if (!value) {
        return nil;
    }
    NSString *string = nil;
    if ([value isKindOfClass:[NSString class]]) {
        string = value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        string = ((NSNumber *)value).stringValue;
    }
    if (!string) {
        return nil;
    }
    return __STURITemplateStringByAddingPercentEscapes([string substringToIndex:MIN(_length, string.length)], preserveCharacters ? __STURITemplateEscapingStyleUR : __STURITemplateEscapingStyleU);
}
- (NSString *)templateRepresentation {
    return [NSString stringWithFormat:@"%@:%lu", self.name, (unsigned long)_length];
}
@end

@implementation __STURITemplateComponentExplodedVariable
- (NSString *)stringWithValue:(id)value preserveCharacters:(BOOL)preserveCharacters {
    NSAssert(0, @"unimplemented");
    return nil;
}
- (NSString *)templateRepresentation {
    return nil;
}
@end


@implementation __STURITemplate {
@private
    NSArray *_components;
}
- (id)init {
    return [self initWithString:nil error:NULL];
}
- (id)initWithString:(NSString *)string {
    return [self initWithString:string error:NULL];
}
- (id)initWithString:(NSString *)string error:(NSError *__autoreleasing *)error {
    __STURITemplateScanner * const scanner = [[__STURITemplateScanner alloc] initWithString:string];
    if (!scanner) {
        return nil;
    }

    NSMutableArray * const components = [[NSMutableArray alloc] init];
    while (![scanner isAtEnd]) {
        id<__STURITemplateComponent> component = nil;
        if (![scanner sturit_scanTemplateComponent:&component]) {
            return nil;
        }
        [components addObject:component];
    }

    if ((self = [super init])) {
        _components = components.copy;
    }
    return self;
}
- (NSArray *)variableNames {
    NSMutableArray * const variableNames = [[NSMutableArray alloc] init];
    for (id<__STURITemplateComponent> component in _components) {
        [variableNames addObjectsFromArray:component.variableNames];
    }
    return variableNames.copy;
}
- (NSString *)string {
    return [self stringByExpandingWithVariables:nil];
}
- (NSString *)stringByExpandingWithVariables:(NSDictionary *)variables {
    NSMutableString * const urlString = [[NSMutableString alloc] init];
    for (id<__STURITemplateComponent> component in _components) {
        NSString * const componentString = [component stringWithVariables:variables];
        if (!componentString) {
            return nil;
        }
        [urlString appendString:componentString];
    }
    return urlString;
}
- (NSURL *)url {
    return [self urlByExpandingWithVariables:nil];
}
- (NSURL *)urlByExpandingWithVariables:(NSDictionary *)variables {
    NSString * const urlString = [self stringByExpandingWithVariables:variables];
    return [NSURL URLWithString:urlString];
}
- (NSString *)templatedStringRepresentation {
    NSMutableString * const templatedString = [[NSMutableString alloc] init];
    for (id<__STURITemplateComponent> component in _components) {
        NSString * const componentString = component.templateRepresentation;
        if (componentString.length) {
            [templatedString appendString:componentString];
        }
    }
    return templatedString.copy;
}
@end
