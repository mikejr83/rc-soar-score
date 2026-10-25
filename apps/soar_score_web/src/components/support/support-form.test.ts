import { expect, test } from "vitest";

import { messageLimit, validate } from "./support-form";

const ok = {
  name: "Ada",
  email: "ada@example.com",
  userType: "",
  requestType: "Feature Request",
  message: "Hello",
};

test("a complete request has no errors", () => {
  expect(validate(ok)).toEqual({});
});

test("required fields and the email shape are checked", () => {
  const errors = validate({ ...ok, name: " ", email: "nope", requestType: "", message: "" });
  expect(Object.keys(errors).sort()).toEqual(["email", "message", "name", "requestType"]);
});

test("the message limit is enforced", () => {
  expect(validate({ ...ok, message: "x".repeat(messageLimit + 1) }).message).toMatch(/under/);
  expect(validate({ ...ok, message: "x".repeat(messageLimit) })).toEqual({});
});
