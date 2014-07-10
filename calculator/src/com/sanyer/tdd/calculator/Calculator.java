package com.sanyer.tdd.calculator;

import java.util.Arrays;
import java.util.List;

public class Calculator {
    public static int add(String text) {
        if (text.isEmpty()) {
            return 0;
        } else if(text.contains(",")) {
            int sum = 0;
            String[] tokens = text.split(",");
            List<String> numbers = Arrays.asList(tokens);
            for(String s : numbers) {
		        sum += toInt(s);
            }
            return sum;
        }
        else {
            return toInt(text);
        }
    }

    private static Converter<String, Integer> toInt() {
        return new Converter<String, Integer>() {

            public Integer convert(String from) {
                return toInt(from);
            }
        };
    }

    private static int toInt(String text) {
        return Integer.parseInt(text);
    }
}
