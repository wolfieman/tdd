package com.sanyer.tdd.shapes.rectangle;

public class Rectangle {
	private double largeur;
	private double hauteur;
	
	public Rectangle() {
	}
	
	public Rectangle(int largeur, int hauteur) {
		this((double)largeur, (double)hauteur);
	}
	
	public Rectangle(double largeur, double hauteur) {
		this.largeur = largeur;
		this.hauteur = hauteur;
	}
	
	public Rectangle(Rectangle autreRectangle) {
		this.largeur = autreRectangle.largeur;
		this.hauteur = autreRectangle.hauteur;
	}
	
	public double getLargeur() {
		return largeur;
	}

	public void setLargeur(double largeur) {
		if (largeur < 0) 
	        throw new IllegalArgumentException("Largeur peut pas être négatif.");
		this.largeur = largeur;
	}

	public double getHauteur() {
		return hauteur;
	}

	public void setHauteur(double hauteur) {
		if (hauteur < 0) {
	        throw new IllegalArgumentException("Hauteur peut pas être négatif.");
		}
		
		this.hauteur = hauteur;
	}

	public double surface() {
		return (isHauteurOrLargeurZero() ? -0.0 : (this.largeur * this.hauteur));
	}
	
	public boolean isHauteurOrLargeurZero() {
		return ((this.hauteur <= 0.0)|| (this.largeur<= 0.0));
	}
	
	public String toString() {
		return "Rectangle -- largeur:  " + this.getLargeur() 
				+ "; hauteur:  " + this.getHauteur()
				+ "; surface:  " + this.surface();
	}
	
	public boolean equals(Rectangle autre) {
		return (autre == null ? false : (this.hauteur == autre.getHauteur() && this.largeur == autre.getLargeur()));
	}
}