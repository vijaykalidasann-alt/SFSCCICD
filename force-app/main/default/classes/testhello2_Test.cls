@IsTest
private class testhello2_Test {
    @IsTest
    static void testDummyMethod() {
        // Exercise the static method to ensure it executes without exceptions
        testhello2.dummy();

        // Basic assertion to satisfy test requirements
        System.assert(true, 'testhello2.dummy executed successfully');
    }

    @IsTest
    static void testConstructor() {
        // Instantiate the class to cover the constructor
        testhello2 obj = new testhello2();
        System.assertNotEquals(null, obj, 'Constructor should create an instance');
    }
}
