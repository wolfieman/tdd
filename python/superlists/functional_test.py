'''
Created on Nov 19, 2014

@author: wolfie
'''
from selenium import webdriver
import unittest

class NewVisitorTest(unittest.TestCase):

    def setUp(self):
        self.browser = webdriver.Firefox()
        self.browser.implicitly_wait(3)

    def tearDown(self):
        self.browser.quit()

    def test_can_start_a_list_and_retrieve_it_later(self):
        # Edith has heard about a cool online to-do app.
        # She goes to check out its homepage
        self.browser.get('http://localhost:8000')

        # She notices the page title & header mention to-do lists
        self.assertIn('To-Do', self.browser.title)
        self.fail('Finish the test!')

        # She is invited to enter a to-do item right away

        # She types "Buy peacock feathers" into a textbox
        # (Edith's hobby is fly-fishing lures)

        # When she hits enter, the page updates, and now the page lists
        # "1. Buy peacock feathers" as an item in a to-do list

        # There is still a textbox inviting her to enter another item.
        # She enters "Use peacock feathers to make a fly" (Edith is very methodical)

        # The page updates again, and now shows both items on her list

        # Edith wonders whether the site will remeber her list.  Then she sees that the
        # site has generated a unique URL for her -- there is some explanatory text to
        # that effect

        # She visits the URL - her to-do list is still there.

        # Satisfied she goes back to sleep

if __name__ == '__main__':
    unittest.main(warnings='ignore')