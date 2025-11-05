@IsTest
private class ExternalCalloutServiceTest {
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertNotEquals(null, req.getEndpoint(), 'Endpoint should be set');
            System.assertNotEquals(null, req.getMethod(), 'Method should be set');

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            // Echo back some JSON to verify round-trip
            String body = '{"ok":true,"endpoint":"' + req.getEndpoint() + '","method":"' + req.getMethod() + '"}';
            res.setBody(body);
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setStatus('Bad Request');
            res.setBody('{"error":"bad_request"}');
            return res;
        }
    }

    @IsTest
    static void test_getJson_success() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        // Using a placeholder Named Credential name.
        // In a real org, create an Enhanced Named Credential with this name, or adjust as needed.
        String nc = 'My_External_API';

        ExternalCalloutService.HttpResponseWrapper res = ExternalCalloutService.getJson(
            nc,
            '/v1/ping',
            new Map<String, String>{ 'q' => '1' }
        );
        System.assertEquals(true, res.isSuccess, 'Expected success');
        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(null, res.body);
        System.assert(res.body.contains('"ok":true'), 'Body should contain ok=true');
    }

    @IsTest
    static void test_postJson_success() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        String nc = 'My_External_API';

        Map<String, Object> payload = new Map<String, Object>{ 'name' => 'Acme' };
        ExternalCalloutService.HttpResponseWrapper res = ExternalCalloutService.postJson(
            nc,
            '/v1/accounts',
            payload,
            null
        );
        System.assertEquals(true, res.isSuccess, 'Expected success');
        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(null, res.body);
    }

    @IsTest
    static void test_error_response() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        String nc = 'My_External_API';

        ExternalCalloutService.HttpResponseWrapper res = ExternalCalloutService.getJson(
            nc,
            '/v1/fail',
            null
        );
        System.assertEquals(false, res.isSuccess, 'Expected failure');
        System.assertEquals(400, res.statusCode);
        System.assertNotEquals(null, res.errorMessage, 'Error message should be set (HTTP 400)');
    }

    @IsTest
    static void test_getJsonAs_deserialize() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        String nc = 'My_External_API';

        // Expect JSON to map to a simple wrapper class
        Type t = Type.forName('ExternalCalloutServiceTest.ResponsePojo');
        Object obj = ExternalCalloutService.getJsonAs(
            nc,
            '/v1/ping',
            new Map<String, String>{ 'q' => '1' },
            t
        );
        System.assertNotEquals(null, obj, 'Deserialized object should not be null');
        ResponsePojo pojo = (ResponsePojo) obj;
        System.assertEquals(true, pojo.ok);
    }

    private class ResponsePojo {
        public Boolean ok;
        public String endpoint;
        public String method;
    }
}
