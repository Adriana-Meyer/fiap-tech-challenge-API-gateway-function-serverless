package com.fiap.workshop.lambda.auth;

// Same checksum algorithm as the app's CpfValidator (Repo 4,
// domain/model/shared/CpfValidator.java) — deliberately duplicated
// here since this Lambda is its own deployable Maven project, kept in
// sync so both reject a malformed CPF before it reaches the app.
public final class CpfValidator {

    private CpfValidator() {}

    public static boolean isValid(String digits) {
        if (digits == null || digits.length() != 11 || !digits.chars().allMatch(Character::isDigit)) {
            return false;
        }
        if (digits.chars().distinct().count() == 1) {
            return false;
        }

        int sum = 0;
        for (int i = 0; i < 9; i++) sum += (digits.charAt(i) - '0') * (10 - i);
        int first = 11 - (sum % 11);
        if (first >= 10) first = 0;

        sum = 0;
        for (int i = 0; i < 10; i++) sum += (digits.charAt(i) - '0') * (11 - i);
        int second = 11 - (sum % 11);
        if (second >= 10) second = 0;

        return first == (digits.charAt(9) - '0') && second == (digits.charAt(10) - '0');
    }
}
