/**
 * ExternalCalloutService
 *
 * Generic, configurable Apex HTTP callout utility supporting GET/POST/PUT/PATCH/DELETE.
 * - Uses Named Credential for endpoint and authentication.
 * - Supports query params, custom headers and configurable timeout.
 * - Includes JSON helpers and typed deserialization.
 *
 * Configuration:
 * - Create a Named Credential (recommended Enhanced Named Credential), e.g. "My_External_API".
 * - Call methods passing the Named Credential name and the relative resource path.
 *
 * Testing:
 * - Use HttpCalloutMock (see ExternalCalloutServiceTest.cls).
 *
 * Author: Agentforce
 * Version: 1.0
 */
public with sharing class ExternalCalloutService {
    /**
     * Wrapper for standardized HTTP response handling
     */
    public class HttpResponseWrapper {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String status;
        @AuraEnabled public String body;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Map<String, String> responseHeaders;

        public HttpResponseWrapper() {}

        public static HttpResponseWrapper fromHttpResponse(HttpResponse resp) {
            HttpResponseWrapper w = new HttpResponseWrapper();
            if (resp != null) {
                w.statusCode = resp.getStatusCode();
                w.status = resp.getStatus();
                w.body = resp.getBody();
                system.debug('vj');
                w.responseHeaders = new Map<String, String>();
                for (String h : resp.getHeaderKeys()) {
                    w.responseHeaders.put(h, resp.getHeader(h));
                }
                w.isSuccess = (w.statusCode != null && w.statusCode >= 200 && w.statusCode < 300);
                if (!w.isSuccess && String.isBlank(w.errorMessage)) {
                    w.errorMessage = 'HTTP ' + w.statusCode + ': ' + w.status;
                }
            } else {
                w.isSuccess = false;
                w.errorMessage = 'Null HttpResponse received';
                system.debug('Test');
            }
            return w;
        }
    }

    // Build Named Credential endpoint like: callout:My_External_API/resource
    private static String buildEndpoint(String namedCredentialName, String resourcePath) {
        String base = 'callout:' + namedCredentialName;
        if (String.isBlank(resourcePath)) return base;
        if (!resourcePath.startsWith('/')) resourcePath = '/' + resourcePath;
        return base + resourcePath;
    }

    // Apply URL-encoded query params
    private static String applyQueryParams(String url, Map<String, String> queryParams) {
        if (queryParams == null || queryParams.isEmpty()) return url;
        List<String> parts = new List<String>();
        for (String key : queryParams.keySet()) {
            String value = queryParams.get(key);
            parts.add(EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(value, 'UTF-8'));
        }
        String qp = String.join(parts, '&');
        return url + (url.contains('?') ? '&' : '?') + qp;
    }

    // Add custom headers (in addition to those from the Named Credential)
    private static void addHeaders(HttpRequest req, Map<String, String> headers) {
        if (headers == null) return;
        for (String key : headers.keySet()) {
            req.setHeader(key, headers.get(key));
        }
    }

    /**
     * Core execute method for all HTTP verbs.
     */
    public static HttpResponseWrapper execute(
        String namedCredentialName,
        String method,
        String resourcePath,
        String requestBody,
        Map<String, String> queryParams,
        Map<String, String> headers,
        Integer timeoutMs
    ) {
        if (String.isBlank(namedCredentialName)) {
            throw new IllegalArgumentException('namedCredentialName is required');
        }
        if (String.isBlank(method)) {
            throw new IllegalArgumentException('HTTP method is required');
        }

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        String endpoint = buildEndpoint(namedCredentialName, resourcePath);
        endpoint = applyQueryParams(endpoint, queryParams);

        req.setEndpoint(endpoint);
        req.setMethod(method);
        if (timeoutMs != null && timeoutMs > 0) {
            req.setTimeout(timeoutMs);
        }
        addHeaders(req, headers);

        if (!String.isBlank(requestBody)) {
            String contentType = (headers != null && headers.containsKey('Content-Type')) ? headers.get('Content-Type') : 'application/json';
            req.setHeader('Content-Type', contentType);
            req.setBody(requestBody);
        }

        try {
            HttpResponse resp = http.send(req);
            return HttpResponseWrapper.fromHttpResponse(resp);
        } catch (CalloutException ex) {
            HttpResponseWrapper w = new HttpResponseWrapper();
            w.isSuccess = false;
            w.errorMessage = 'CalloutException: ' + ex.getMessage();
            return w;
        } catch (Exception ex) {
            HttpResponseWrapper w = new HttpResponseWrapper();
            w.isSuccess = false;
            w.errorMessage = 'Exception: ' + ex.getMessage();
            return w;
        }
    }

    // Convenience JSON helpers

    public static HttpResponseWrapper getJson(
        String namedCredentialName,
        String resourcePath,
        Map<String, String> queryParams
    ) {
        return execute(namedCredentialName, 'GET', resourcePath, null, queryParams, null, 120000);
    }

    public static Object getJsonAs(
        String namedCredentialName,
        String resourcePath,
        Map<String, String> queryParams,
        Type targetType
    ) {
        HttpResponseWrapper res = getJson(namedCredentialName, resourcePath, queryParams);
        if (res.isSuccess && !String.isBlank(res.body)) {
            return (Object) JSON.deserialize(res.body, targetType);
        }
        return null;
    }

    public static HttpResponseWrapper postJson(
        String namedCredentialName,
        String resourcePath,
        Object body,
        Map<String, String> queryParams
    ) {
        String jsonBody = body == null ? null : JSON.serialize(body);
        Map<String, String> headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
        return execute(namedCredentialName, 'POST', resourcePath, jsonBody, queryParams, headers, 120000);
    }

    public static HttpResponseWrapper postJsonRaw(
        String namedCredentialName,
        String resourcePath,
        String jsonBody,
        Map<String, String> queryParams
    ) {
        Map<String, String> headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
        return execute(namedCredentialName, 'POST', resourcePath, jsonBody, queryParams, headers, 120000);
    }

    public static HttpResponseWrapper putJson(
        String namedCredentialName,
        String resourcePath,
        Object body,
        Map<String, String> queryParams
    ) {
        String jsonBody = body == null ? null : JSON.serialize(body);
        Map<String, String> headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
        return execute(namedCredentialName, 'PUT', resourcePath, jsonBody, queryParams, headers, 120000);
    }

    public static HttpResponseWrapper patchJson(
        String namedCredentialName,
        String resourcePath,
        Object body,
        Map<String, String> queryParams
    ) {
        String jsonBody = body == null ? null : JSON.serialize(body);
        Map<String, String> headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
        return execute(namedCredentialName, 'PATCH', resourcePath, jsonBody, queryParams, headers, 120000);
    }

    public static HttpResponseWrapper delete(
        String namedCredentialName,
        String resourcePath,
        Map<String, String> queryParams
    ) {
        return execute(namedCredentialName, 'DELETE', resourcePath, null, queryParams, null, 120000);
    }
}
