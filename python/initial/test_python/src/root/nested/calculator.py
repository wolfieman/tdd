'''
Created on Nov 15, 2014

@author: wolfie
'''

class Calculator(object):
    '''
    classdocs
    '''

    def __init__(self):
        self.current = 0
    def add(self, x, y):
        self.current = x + y
        return self.current
    def getCurrent(self):
        return self.current
