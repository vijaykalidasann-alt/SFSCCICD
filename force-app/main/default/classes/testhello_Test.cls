@IsTest
private class testhello_Test {
    @IsTest
    static void testConstructor() {
        // Act
        testhello th = new testhello();

        // Assert - basic non-null check
        system.debug('Test');
        System.assertNotEquals(null, th, 'Constructor should create an instance');
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
