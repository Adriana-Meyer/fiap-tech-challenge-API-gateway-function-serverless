package com.fiap.workshop.lambda.auth;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;

public class AuthHandler implements RequestHandler<APIGatewayV2HTTPEvent, APIGatewayV2HTTPResponse> {

    private static final String APP_LOGIN_URL = System.getenv("APP_LOGIN_URL");
    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();

    @Override
    public APIGatewayV2HTTPResponse handleRequest(APIGatewayV2HTTPEvent event, Context context) {
        Map<String, Object> body;
        try {
            body = MAPPER.readValue(event.getBody() == null ? "{}" : event.getBody(), Map.class);
        } catch (Exception e) {
            return jsonResponse(400, Map.of("message", "Invalid JSON body"));
        }

        Object cpfValue = body.get("cpf");
        Object passwordValue = body.get("password");

        if (!(cpfValue instanceof String cpf) || !(passwordValue instanceof String password)
                || cpf.isBlank() || password.isBlank()) {
            return jsonResponse(400, Map.of("message", "cpf and password are required"));
        }

        if (!CpfValidator.isValid(cpf)) {
            return jsonResponse(400, Map.of("message", "Invalid CPF"));
        }

        try {
            String requestBody = MAPPER.writeValueAsString(Map.of("cpf", cpf, "password", password));
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(APP_LOGIN_URL))
                    .timeout(Duration.ofSeconds(8))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                    .build();

            HttpResponse<String> response = HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofString());

            return APIGatewayV2HTTPResponse.builder()
                    .withStatusCode(response.statusCode())
                    .withHeaders(Map.of("Content-Type", "application/json"))
                    .withBody(response.body())
                    .build();
        } catch (Exception e) {
            context.getLogger().log("Failed to reach the app login endpoint: " + e.getMessage());
            return jsonResponse(502, Map.of("message", "Authentication service unavailable"));
        }
    }

    private APIGatewayV2HTTPResponse jsonResponse(int statusCode, Map<String, Object> body) {
        try {
            return APIGatewayV2HTTPResponse.builder()
                    .withStatusCode(statusCode)
                    .withHeaders(Map.of("Content-Type", "application/json"))
                    .withBody(MAPPER.writeValueAsString(body))
                    .build();
        } catch (Exception e) {
            return APIGatewayV2HTTPResponse.builder()
                    .withStatusCode(500)
                    .withBody("{\"message\":\"internal error\"}")
                    .build();
        }
    }
}
