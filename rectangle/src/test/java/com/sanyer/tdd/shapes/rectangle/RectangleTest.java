package com.sanyer.tdd.shapes.rectangle;

import com.sanyer.tdd.shapes.rectangle.Rectangle;

import org.junit.Assert;
import org.junit.Test;


public class RectangleTest {
  @Test
  public final void whenBothHeigthAndLengthAreZero() {
	  Rectangle rectangle = new Rectangle();
      Assert.assertEquals(0, rectangle.surface(), .01);
  }
  
  @Test
  public final void whenHeigthOrLengthAreZero() {
	  Rectangle rectangle = new Rectangle();
	  rectangle.setHauteur(3.0);
      Assert.assertEquals(0, rectangle.surface(), .01);
  }
  
  @Test (expected = IllegalArgumentException.class)
  public final void whenNotZeroButOneIsNegative() {
	  Rectangle rectangle = new Rectangle();
	  rectangle.setHauteur(3.0);
	  rectangle.setLargeur(-4.0);
      Assert.assertEquals(0, rectangle.surface(), .01);
  }
  
  @Test
  public final void whithGoodValues() {
	  Rectangle rectangle = new Rectangle();
	  rectangle.setHauteur(3.0);
	  rectangle.setLargeur(4.0);
      Assert.assertEquals(12, rectangle.surface(), .01);
  }
}