'''
Created on Nov 15, 2014

@author: wolfie
'''
############
# This is a compilation of the examples from Week 1's Programming Tips.
# Many of these functions have errors, so this file won't run as is.
############


import random


############
# Has multiple NameErrors
def volume_cube(side):
    return side ** 3

s = 2
print ("Volume of cube with side ", s, " is ", volume_cube(s), ".", sep="")
print("There are <", 2**32, "> possibilities!", sep="")

############
# Has a NameError
def random_dice():
    die1 = random.randrange(1, 7)
    die2 = random.randrange(1, 7)
    return die1 + die2

print ("Sum of two random dice, rolled once:", random_dice())
print ("Sum of two random dice, rolled again:", random_dice())
print ("Sum of two random dice, rolled again:", random_dice())


############


