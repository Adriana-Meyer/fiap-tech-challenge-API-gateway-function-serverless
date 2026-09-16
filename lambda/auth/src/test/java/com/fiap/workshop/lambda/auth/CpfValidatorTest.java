package com.fiap.workshop.lambda.auth;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CpfValidatorTest {

    @Test
    void acceptsValidCpf() {
        assertTrue(CpfValidator.isValid("52998224725"));
    }

    @Test
    void rejectsWrongCheckDigits() {
        assertFalse(CpfValidator.isValid("52998224726"));
    }

    @Test
    void rejectsAllRepeatedDigits() {
        assertFalse(CpfValidator.isValid("11111111111"));
    }

    @Test
    void rejectsWrongLength() {
        assertFalse(CpfValidator.isValid("123"));
    }

    @Test
    void rejectsNonNumeric() {
        assertFalse(CpfValidator.isValid("abc.def.ghi"));
    }

    @Test
    void rejectsNull() {
        assertFalse(CpfValidator.isValid(null));
    }
}
