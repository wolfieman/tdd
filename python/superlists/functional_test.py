'''
Created on Nov 19, 2014

@author: wolfie
'''
from selenium import webdriver

browser = webdriver.Firefox()
browser.get('http://localhost:8000')

print(browser.title)

assert 'Django' in browser.title