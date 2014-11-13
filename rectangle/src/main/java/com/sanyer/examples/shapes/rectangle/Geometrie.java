package com.sanyer.examples.shapes.rectangle;

import java.util.Scanner;

import com.sanyer.tdd.shapes.rectangle.Rectangle;

public class Geometrie {
	private final static Scanner CLAVIER = new Scanner(System.in);

	public static void main(String[] args) {
		Rectangle rect = new Rectangle();
		try {
			System.out.print("Quelle hauteur? ");
			rect.setHauteur(CLAVIER.nextDouble());
			System.out.print("Quelle largeur? ");
			rect.setLargeur(CLAVIER.nextDouble());
			
			System.out.println("surface = " + rect.surface());
			System.out.println(rect.toString());
		} catch (IllegalArgumentException iae) {
			System.out.println(iae.getMessage());
		}
		rect = null;
	}

}
