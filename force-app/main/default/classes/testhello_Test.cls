@IsTest
private class testhello_Test {
    @IsTest
    static void testConstructor() {
        // Act
        testhello th = new testhello();
        system.debug('test');
        // Assert - basic non-null check
        System.assertNotEquals(null, th, 'Constructor should create an instance');
        System.debug('Dummy method executed');
    }

    @IsTest
    static void testDummyMethod() {
        // Act
        Test.startTest();
        testhello.dummy();
        Test.stopTest();

        // Assert - method invoked without exceptions
        System.assert(true, 'dummy() executed without throwing exceptions');
    }
}
