### Exercise

Afer the changes to __experiment 4__ have been applied, provide support for displaying multiple characters associated with the PS/2 keys that were pressed. In particular, you must display the first 15 keys that were pressed on the PS/2 keyboard. Assume only the numerical keys are tracked, hence if a PS/2 key that is not a numerical key has been pressed, display space. Assume also the 15 characters associated with the first 15 keys that were pressed are displayed on the same character row (you can choose an arbitrary position where to display the row so long as all the characters are visible). 

For the displayed 15-character message, identify the numerical key that appeared most times. In the case of a tie-break, the key with a higher numerical id takes precedence. For example, if key 2 was pressed 3 times, key 6 was pressed 3 times and key 3 was pressed 3 times then display:

KEY 6 PRESSED 3 TIMES

In case the same key has been pressed more than 9 times, then its value should be displayed in binary-coded decimal (BCD) format. Note, if no numerical key has been pressed then display the message:

NO NUM KEYS PRESSED

In simulation you should choose to schedule the PS/2 key events such that the registers that hold the history of the keystrokes are updated __ONLY__ during the vertical blanking interval. Hence, the message to be displayed for a frame should be decided before the end of the vertical blanking interval. 

In your report you must discuss your resource usage in terms of registers. You should relate your estimate to the register count from the compilation report in Quartus.

Submit your sources and in your report write approx half-a-page (but not more than full page) that describes your reasoning. Your sources should follow the directory structure from the in-lab experiments (already set-up for you in the `exercise` folder); note, your report (in `.pdf`, `.txt` or `.md` format) should be included in the `exercise/doc` sub-folder. Note also, your design must pass compilation in Quartus before you simulate it and you write the report.

Your submission is due 14 hours before your next lab session. Late submissions will be penalized.

