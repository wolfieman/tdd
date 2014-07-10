package com.sanyer.tdd.calculator;

import org.junit.Test;
import static org.junit.Assert.*;

public class CalculatorTest {
    StringBuffer text;

    @Test()
    public void shouldReturnZeroOnEmptyString() {
        assertEquals(0, Calculator.add(""));
    }

    @Test()
    public void shouldReturnNumberOnNumber() {
        assertEquals(1, Calculator.add("1"));
    }

    @Test()
    public void shouldReturnSumOnTwoNumbersDelimitedByComas() {
        assertEquals(3, Calculator.add("1,2"));
    }

    @Test()
    public void shouldReturnSumOnMultipleNumbers() {
        assertEquals(6, Calculator.add("1,2,3"));
    }
}
