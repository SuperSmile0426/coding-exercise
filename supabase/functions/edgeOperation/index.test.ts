import { assertEquals } from "https://deno.land/std@0.208.0/testing/asserts.ts";
import { handler } from "./index.ts";

// Helper function to create a Request object with query parameters
function createRequest(params: Record<string, string>): Request {
  const queryString = new URLSearchParams(params).toString();
  return new Request(`http://localhost:8000/?${queryString}`);
}

// Test cases for string reversal
Deno.test("String reversal operation", async (t) => {
  await t.step("should reverse a string", async () => {
    const request = createRequest({
      operation: "reverse",
      text: "hello",
    });
    const response = await handler(request);
    const data = await response.json();
    assertEquals(data, { reversed: "olleh" });
  });

  await t.step("should handle empty string", async () => {
    const request = createRequest({
      operation: "reverse",
      text: "",
    });
    const response = await handler(request);
    const data = await response.json();
    assertEquals(data, { reversed: "" });
  });

  await t.step("should handle default operation", async () => {
    const request = createRequest({
      text: "hello",
    });
    const response = await handler(request);
    const data = await response.json();
    assertEquals(data, { reversed: "olleh" });
  });
});

// Test cases for random number generation
Deno.test("Random number generation", async (t) => {
  await t.step("should generate number within range", async () => {
    const request = createRequest({
      operation: "random",
      min: "1",
      max: "10",
    });
    const response = await handler(request);
    const data = await response.json();
    assertEquals(typeof data.random, "number");
    assertEquals(data.random >= 1 && data.random <= 10, true);
  });

  await t.step("should use default range when not specified", async () => {
    const request = createRequest({
      operation: "random",
    });
    const response = await handler(request);
    const data = await response.json();
    assertEquals(typeof data.random, "number");
    assertEquals(data.random >= 0 && data.random <= 100, true);
  });

  await t.step("should handle invalid range", async () => {
    const request = createRequest({
      operation: "random",
      min: "10",
      max: "5", // min > max
    });
    const response = await handler(request);
    const data = await response.json();
    assertEquals(typeof data.random, "number");
    assertEquals(data.random >= 5 && data.random <= 10, true);
  });
});

// Test cases for timestamp formatting
Deno.test("Timestamp formatting", async (t) => {
  await t.step("should return ISO format by default", async () => {
    const request = createRequest({
      operation: "timestamp",
    });
    const response = await handler(request);
    const data = await response.json();
    assertEquals(typeof data.timestamp, "string");
    assertEquals(new Date(data.timestamp).toString() !== "Invalid Date", true);
  });

  await t.step("should return Unix timestamp when specified", async () => {
    const request = createRequest({
      operation: "timestamp",
      format: "unix",
    });
    const response = await handler(request);
    const data = await response.json();
    assertEquals(typeof data.timestamp, "number");
    assertEquals(data.timestamp > 0, true);
  });

  await t.step("should handle invalid format", async () => {
    const request = createRequest({
      operation: "timestamp",
      format: "invalid",
    });
    const response = await handler(request);
    const data = await response.json();
    assertEquals(typeof data.timestamp, "string");
    assertEquals(new Date(data.timestamp).toString() !== "Invalid Date", true);
  });
});

// Test cases for error handling
Deno.test("Error handling", async (t) => {
  await t.step("should return error for invalid operation", async () => {
    const request = createRequest({
      operation: "invalid_operation",
    });
    const response = await handler(request);
    assertEquals(response.status, 400);
    const data = await response.json();
    assertEquals(data, { error: "Invalid operation" });
  });
});