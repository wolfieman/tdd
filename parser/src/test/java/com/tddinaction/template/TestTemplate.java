package com.tddinaction.template;

import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class TestTemplate {
    @Test
    public void oneVariable() throws Exception {
        Template template = new Template("Hello, ${name}");
        template.set("name", "Reader");
        assertEquals("Hello, Reader", template.evaluate());
    }

     @Test
    public void differentTemplate() throws Exception {
        Template template = new Template("Hi, ${name}");
        template.set("name", "someone else");
        assertEquals("Hi, someone else", template.evaluate());
    }

    @Test
    public void multipleVariables() throws Exception {
        Template template = new Template("${one}, ${two}, ${three}");
        template.set("one", "1");
        template.set("two", "2");
        template.set("three", "3");
        assertEquals("1, 2, 3", template.evaluate());
    }

    @Test
    public void unknownVariablesAreIgnored() throws Exception {
        Template template = new Template("Hello, ${name}");
        template.set("name", "Reader");
        template.set("doesnotexist", "Hi");
        template.set("three", "3");
        assertEquals("Hello, Reader", template.evaluate());
    }

    @Test
    public void printStackTraceTest() throws Exception {
        try
        {
           String badString = null;
           String newString = "Hey";

           newString.concat(badString);
//           System.out.println(badString);
        }
        catch (NullPointerException npe)
        {
//            System.out.println(npe.getMessage());
            npe.printStackTrace();
        }
    }
}
