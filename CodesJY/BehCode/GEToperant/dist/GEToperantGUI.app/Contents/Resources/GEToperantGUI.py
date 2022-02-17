from tkinter import *
from tkinter.filedialog import *
from tkinter.messagebox import *
##from tkinter.filedialog import askopenfilenames
##from tkinter.filedialog import asksaveasfilename
import GEToperant

GETprofile = None
MPC_filenames = None

#Define functions for the menus
def openprofile():
    global GETprofile
    GETprofile = askopenfilename(title = 'Select data profile', filetypes =  [('Excel GEToperant Profile', '*.xlsx'), ('MPC2XL Row Profile', '*.MRP')])

def opendata():
    global MPC_filenames
    MPC_filenames = askopenfilenames(title = 'Select files to import')

def saveoutput():
    outputfile = asksaveasfilename(title = 'Save output file as', defaultextension='.xlsx', filetypes=(('Excel', '*.xlsx'),('All Files', '*.*')))
    if GETprofile == None or MPC_filenames == None or len(GETprofile) < 1 or len(MPC_filenames) < 1 or len(outputfile) < 1:
        showerror('Error!', 'Please select a data profile, at least one Med-PC data file and a define a save file.')
    else:
        GEToperant.GEToperant(GETprofile, MPC_filenames, outputfile,
                              exportfilename = Header_Filename.get(),
                              exportstartdate = Header_StartDate.get(),
                              exportenddate = Header_EndDate.get(),
                              exportsubject = Header_Subject.get(),
                              exportexperiment = Header_Experiment.get(),
                              exportgroup = Header_Group.get(),
                              exportbox = Header_Box.get(),
                              exportstarttime = Header_StartTime.get(),
                              exportendtime = Header_EndTime.get(),
                              exportmsn = Header_MSN.get(),
                              mode = 'Main')

def saveoutputsheet():
    outputfile = asksaveasfilename(title = 'Save output file as', defaultextension='.xlsx', filetypes=(('Excel', '*.xlsx'),('All Files', '*.*')))
    if GETprofile == None or MPC_filenames == None or len(GETprofile) < 1 or len(MPC_filenames) < 1 or len(outputfile) < 1:
        showerror('Error!', 'Please select a data profile, at least one Med-PC data file and a define a save file.')
    else:
        GEToperant.GEToperant(GETprofile, MPC_filenames, outputfile,
                              exportfilename = Header_Filename.get(),
                              exportstartdate = Header_StartDate.get(),
                              exportenddate = Header_EndDate.get(),
                              exportsubject = Header_Subject.get(),
                              exportexperiment = Header_Experiment.get(),
                              exportgroup = Header_Group.get(),
                              exportbox = Header_Box.get(),
                              exportstarttime = Header_StartTime.get(),
                              exportendtime = Header_EndTime.get(),
                              exportmsn = Header_MSN.get(),
                              mode = 'Sheets')

def saveoutputbooks():
    outputfile = askdirectory(title = 'Select directory to save exported files to')
    if GETprofile == None or MPC_filenames == None or len(GETprofile) < 1 or len(MPC_filenames) < 1 or len(outputfile) < 1:
        showerror('Error!', 'Please select a data profile, at least one Med-PC data file and a define a save file.')
    else:
        GEToperant.GEToperant(GETprofile, MPC_filenames, outputfile,
                              exportfilename = Header_Filename.get(),
                              exportstartdate = Header_StartDate.get(),
                              exportenddate = Header_EndDate.get(),
                              exportsubject = Header_Subject.get(),
                              exportexperiment = Header_Experiment.get(),
                              exportgroup = Header_Group.get(),
                              exportbox = Header_Box.get(),
                              exportstarttime = Header_StartTime.get(),
                              exportendtime = Header_EndTime.get(),
                              exportmsn = Header_MSN.get(),
                              mode = 'Books')

#Define functions for the buttons
def RunExport():
    exmode = Export_Mode.get()
    if exmode == 1:
        GETexpress()
    elif exmode == 2:
        GETsheets()
    elif exmode == 3:
        GETbooks()

def convertprofile():
    GETprofile = askopenfilename(title = 'Select data profile', filetypes =  [('MPC2XL Row Profile', '*.MRP')])
    if len(GETprofile) < 1:
        showerror('Error!', 'Please select a MPC2XL Row Profile.')
        return None
    profileexport = asksaveasfilename(title = 'Save converted profile as', defaultextension='.xlsx', filetypes=[('Excel', '*.xlsx')])
    if len(profileexport) < 1:
        showerror('Error!', 'Please choose a save file.')
        return None
    else:
        GEToperant.convertMRP(GETprofile = GETprofile, profileexport = profileexport)

def GETexpress():
    GETprofile = askopenfilename(title = 'Select data profile', filetypes =  [('Excel GEToperant Profile', '*.xlsx'), ('MPC2XL Row Profile', '*.MRP')])
    if len(GETprofile) < 1:
        showerror('Error!', 'Please select a data profile')
        return None
    MPC_filenames = askopenfilenames(title = 'Select files to import')
    if len(MPC_filenames) < 1:
        showerror('Error!', 'Please select at least one Med-PC data file.')
        return None
    outputfile = asksaveasfilename(title = 'Save output file as', defaultextension='.xlsx', filetypes=(('Excel', '*.xlsx'),('All Files', '*.*')))
    if len(outputfile) < 1:
        showerror('Error!', 'Please select an output file.')
        return None
    elif '.xls' not in outputfile[-4:] and '.xlsx' not in outputfile[-5:]:
        outputfile = outputfile + '.xlsx'
    GEToperant.GEToperant(GETprofile, MPC_filenames, outputfile,
                                  exportfilename = Header_Filename.get(),
                                  exportstartdate = Header_StartDate.get(),
                                  exportenddate = Header_EndDate.get(),
                                  exportsubject = Header_Subject.get(),
                                  exportexperiment = Header_Experiment.get(),
                                  exportgroup = Header_Group.get(),
                                  exportbox = Header_Box.get(),
                                  exportstarttime = Header_StartTime.get(),
                                  exportendtime = Header_EndTime.get(),
                                  exportmsn = Header_MSN.get(),
                                  mode = 'Main')

def GETsheets():
    GETprofile = askopenfilename(title = 'Select data profile', filetypes =  [('Excel GEToperant Profile', '*.xlsx'), ('MPC2XL Row Profile', '*.MRP')])
    if len(GETprofile) < 1:
        showerror('Error!', 'Please select a data profile')
        return None
    MPC_filenames = askopenfilenames(title = 'Select files to import')
    if len(MPC_filenames) < 1:
        showerror('Error!', 'Please select at least one Med-PC data file.')
        return None
    outputfile = asksaveasfilename(title = 'Save output file as', defaultextension='.xlsx', filetypes=(('Excel', '*.xlsx'),('All Files', '*.*')))
    if len(outputfile) < 1:
        showerror('Error!', 'Please select an output file.')
        return None
    elif '.xls' not in outputfile[-4:] and '.xlsx' not in outputfile[-5:]:
        outputfile = outputfile + '.xlsx'
    GEToperant.GEToperant(GETprofile, MPC_filenames, outputfile,
                                  exportfilename = Header_Filename.get(),
                                  exportstartdate = Header_StartDate.get(),
                                  exportenddate = Header_EndDate.get(),
                                  exportsubject = Header_Subject.get(),
                                  exportexperiment = Header_Experiment.get(),
                                  exportgroup = Header_Group.get(),
                                  exportbox = Header_Box.get(),
                                  exportstarttime = Header_StartTime.get(),
                                  exportendtime = Header_EndTime.get(),
                                  exportmsn = Header_MSN.get(),
                                  mode = 'Sheets')

def GETbooks():
    GETprofile = askopenfilename(title = 'Select data profile', filetypes =  [('Excel GEToperant Profile', '*.xlsx'), ('MPC2XL Row Profile', '*.MRP')])
    if len(GETprofile) < 1:
        showerror('Error!', 'Please select a data profile')
        return None
    MPC_filenames = askopenfilenames(title = 'Select files to import')
    if len(MPC_filenames) < 1:
        showerror('Error!', 'Please select at least one Med-PC data file.')
        return None
    outputfile = askdirectory(title = 'Select directory to save exported files to')
    if len(outputfile) < 1:
        showerror('Error!', 'Please select an output directory.')
        return None
    else:
        GEToperant.GEToperant(GETprofile, MPC_filenames, outputfile,
                                      exportfilename = Header_Filename.get(),
                                      exportstartdate = Header_StartDate.get(),
                                      exportenddate = Header_EndDate.get(),
                                      exportsubject = Header_Subject.get(),
                                      exportexperiment = Header_Experiment.get(),
                                      exportgroup = Header_Group.get(),
                                      exportbox = Header_Box.get(),
                                      exportstarttime = Header_StartTime.get(),
                                      exportendtime = Header_EndTime.get(),
                                      exportmsn = Header_MSN.get(),
                                      mode = 'Books')
    
def helpme():
    helpwindow = Toplevel()
    helpwindow.title('How to use GEToperant')
    helptext = Text(helpwindow, height = 30, width = 80)
    helptext.pack(side= 'top')
    scroll = Scrollbar(helpwindow, command = helptext.yview)
    helptext.configure(yscrollcommand = scroll.set)
    helptext.tag_configure('regular', font=('Verdana', 11))
    howtoGET = """
    How to use GEToperant

    Using GEToperant involves four steps.
    1. Create a data profile
    2. Use the checkboxes to select which headers you wish to export
    3. Click on the button that corresponds to the output you want
    4. Follow the prompts to select your data profile and files

    Your data profile tells GEToperant what data you want extracted
    and what to label each element as. You can extract:
    - a single element
    - a section of an array
    - a whole array

    You can also use MPC2XL Row Profiles (MRPs) to extract your data
    or convert an MRP to an GEToperant profile.

    Your data profile needs to have up to 7 pieces of information:
    1. A Label
    2. A Label Start Value
    3. A Label Increment
    4. An Array or Variable
    5. The Start Element
    6. The Increment Element
    7. The Stop Element

    In order to extract a single element you will need to define:
    - The Label
    - The Array or Variable
    - The Start Element (i.e. the element you want extracted)
    - The Increment Element (which must equal 0)

    For example, the element A(0) contains the total lever responses.
    You would define the label as 'Lever Presses', the Array as 'A',
    the Start Element as 0 and the Increment Element as 0. This tells
    GEToperant to get the element A(0) from all sessions in the data
    files you load and to label it 'Lever Presses'.

    In order to extract a section of an array you need:
    - The label
    - The Array or Variable
    - The Start Element
    - The Increment Element
    - The Stop Element
    You can also use:
    - The Label Start Value
    - The Label Increment

    Your Stop Element must be greater than your Start Element and
    your Increment Element must be greater than 0. This will tell
    GEToperant to start at a particular part of the array and keep
    going up by the increments you define until it reaches the Stop
    Element. So if you wanted every second value of the B array from
    beginning to element 30, you would set the Start Element to 0,
    the Incremenet Element to 2 and the Stop Element to 30.

    The Label Increment and Label Start Value are optional and allow
    you to define a value to put at the end of your label. This is
    useful for a series like timebins. For example, you could have
    a label of 'Responses Min' with a Label Start Value of 1 and a
    Label Increment of 1. You would then get 'Responses Min 1',
    'Responses Min 2', 'Responses Min 3' and so on.

    In order to extract an array until it ends you will need the same
    details as required to extract a section of an array except you
    should leave the Stop Element blank or write something in it, such
    as 'End'. However, any text string will be read as the end of the
    array.

    Session comments are not extracted automatically. In order to
    extract comments provide:
    - The Label
    - An Array or Variable with the word 'comment' in it (this is not
    case sensitive)
    - A Start Element and Increment Element of 0

    Once you have your data profile, you can select your headers.
    All headers are selected by default.

    You can export your data as:
    1. A single worksheet
    2. Separate sheets
    3. Separate books

    Click on the button corresponding to the type of output you want and
    GEToperant will display windows to select the appropriate files.

    For a single worksheet, GEToperant will save all data to one sheet
    on one Excel file.
    For separate sheets, GEToperant will save each data file in a separate
    worksheet, but in one Excel file.
    For separate books, GEToperant will save each data file in a separate
    Excel file, named after the file that it corresponds to.
    """
    helptext.insert(END, howtoGET, 'regular')
    helptext.pack(side=LEFT)
    scroll.pack(side=RIGHT, fill = Y)

def aboutGET():
    aboutme = Toplevel()
    aboutme.title('About GEToperant')
    abouttext = Text(aboutme, height = 22, width = 75)
    abouttext.pack(side= 'top')
    abouttext.tag_configure('regular', font=('Verdana', 11))
    about = """
    GEToperant is a general extraction tool for Med-PC®.
    It was designed to be compatible with Med-PC® IV but given how
    little Med-PC® changes, it should be compatible with Med-PC® V.
    It was written by Shaun Khoo using Python 3.4.4 with the xlrd
    and xlsxwriter packages. Executable files were produced using pyinstaller.
    
    It is free open source software available under an MIT license.
    You pay nothing and you can do with it as you please.

    If you have enjoyed using GEToperant, please tell your friends or
    reference it in one of your publications.

    For the latest version and source code visit:
    https://github.com/SKhoo/GEToperant/
    For up to date contact information visit:
    https://orcid.org/0000-0002-0972-3788
    """
    abouttext.insert(END, about, 'regular')
    abouttext.pack(side=LEFT)

def licenseMIT():
    licenseme = Toplevel()
    licenseme.title('GEToperant MIT License')
    MIT = Text(licenseme, height = 31, width = 60)
    MIT.pack(side= 'top')
    MIT.tag_configure('regular', font=('Arial', 11))
    MITtext = """
    MIT License

    Copyright (c) 2018 Shaun Khoo

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge,
    publish, distribute, sublicense, and/or sell copies of the Software,
    and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
    OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
    NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
    CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
    OR IN CONNECTION WITH THE SOFTWARE OR THE USE
    OR OTHER DEALINGS IN THE SOFTWARE.
    """
    MIT.insert(END, MITtext, 'regular')
    MIT.pack(side=LEFT)

def quit():
    root.destroy()

root = Tk()

##Set window size
root.geometry('876x500')
root.title('GEToperant v1.0 >(\' . \')<')
Montre = PhotoImage(file='icon.pnm')
root.wm_iconphoto('True', Montre)

#Display header logo
Kip = PhotoImage(file='logo.pnm')
displaylogo = Label(root, image = Kip).grid(row = 0)

##Checkbox options
Label(root, text = 'Select headers to export:', font=('Verdana', 11)).grid(row = 1)
Cboxes1 = Frame(height = 80, width = 876)
Cboxes1.grid(row = 2)
Header_Filename = IntVar(value = 1)
Checkbutton(Cboxes1, text= 'Filename', variable = Header_Filename, font=('Verdana', 9)).grid(row = 0, column = 0, sticky = W, padx = 15)
Header_StartDate = IntVar(value = 1)
Checkbutton(Cboxes1, text= 'Start Date', variable = Header_StartDate, font=('Verdana', 9)).grid(row = 0, column = 1, sticky = W, padx = 15)
Header_EndDate = IntVar(value = 1)
Checkbutton(Cboxes1, text = 'End Date', variable = Header_EndDate, font=('Verdana', 9)).grid(row = 0, column = 2, sticky = W, padx = 15)
Header_Subject = IntVar(value = 1)
Checkbutton(Cboxes1, text = 'Subject', variable = Header_Subject, font=('Verdana', 9)).grid(row = 0, column = 3, sticky = W, padx = 15)
Header_Experiment = IntVar(value = 1)
Checkbutton(Cboxes1, text = 'Experiment', variable = Header_Experiment, font=('Verdana', 9)).grid(row = 0, column = 4, sticky = W, padx = 15)
Header_Group = IntVar(value = 1)
Checkbutton(Cboxes1, text = 'Group', variable = Header_Group, font=('Verdana', 9)).grid(row = 1, column = 0, sticky = W, padx = 15)
Header_Box = IntVar(value = 1)
Checkbutton(Cboxes1, text = 'Box', variable = Header_Box, font=('Verdana', 9)).grid(row = 1, column = 1, sticky = W, padx = 15)
Header_StartTime = IntVar(value = 1)
Checkbutton(Cboxes1, text = 'Start Time', variable = Header_StartTime, font=('Verdana', 9)).grid(row = 1, column = 2, sticky = W, padx = 15)
Header_EndTime = IntVar(value = 1)
Checkbutton(Cboxes1, text = 'End Time', variable = Header_EndTime, font=('Verdana', 9)).grid(row = 1, column = 3, sticky = W, padx = 15)
Header_MSN = IntVar(value = 1)
Checkbutton(Cboxes1, text = 'MSN (Program Name)', variable = Header_MSN, font=('Verdana', 9)).grid(row = 1, column = 4, sticky = W, padx = 15)

## Menus
menu = Menu(root)
root.config(menu = menu)
filemenu = Menu(menu)
menu.add_cascade(label = 'File', menu = filemenu)
filemenu.add_command(label = 'Select Profile', command = openprofile)
filemenu.add_command(label = 'Open Data File(s)', command = opendata)
filemenu.add_command(label = 'Save Output: One Sheet, One Workbook', command = saveoutput)
filemenu.add_command(label = 'Save Output: Data Files on Separate Sheets', command = saveoutputsheet)
filemenu.add_command(label = 'Save Output: Data Files in Separate Workbooks', command = saveoutputbooks)
filemenu.add_separator()
filemenu.add_command(label = 'Convert MPC2XL Row Profile', command = convertprofile)
filemenu.add_separator()
filemenu.add_command(label = 'Close', command = root.quit)
                                 
helpmenu = Menu(menu)
menu.add_cascade(label = 'Help', menu = helpmenu)
helpmenu.add_command(label = 'How to use GEToperant', command = helpme)
helpmenu.add_command(label = 'About', command = aboutGET)
helpmenu.add_command(label = 'License', command = licenseMIT)

class CreateToolTip(object):
    def __init__(self, widget, text='widget info'):
        self.waittime = 500
        self.wraplength = 400
        self.widget = widget
        self.text = text
        self.widget.bind("<Enter>", self.enter)
        self.widget.bind("<Leave>", self.leave)
        self.widget.bind("<ButtonPress>", self.leave)
        self.id = None
        self.tw = None

    def enter(self, event=None):
        self.schedule()

    def leave(self, event=None):
        self.unschedule()
        self.hidetip()

    def schedule(self):
        self.unschedule()
        self.id = self.widget.after(self.waittime, self.showtip)

    def unschedule(self):
        id = self.id
        self.id = None
        if id:
            self.widget.after_cancel(id)

    def showtip(self, event=None):
        x = y = 0
        x, y, cx, cy = self.widget.bbox("insert")
        x += self.widget.winfo_rootx() + 50
        y += self.widget.winfo_rooty() - 20
        # creates a toplevel window
        self.tw = Toplevel(self.widget)
        # Leaves only the label and removes the app window
        self.tw.wm_overrideredirect(True)
        self.tw.wm_geometry("+%d+%d" % (x, y))
        label = Label(self.tw, text=self.text, justify='left',
                       background="#ffffff", relief='solid', borderwidth=1,
                       wraplength = self.wraplength)
        label.pack(ipadx=1)

    def hidetip(self):
        tw = self.tw
        self.tw= None
        if tw:
            tw.destroy()

class App:
    def __init__(self, master):
        frame = Frame(height = 80, width = 876)
        frame.grid(row = 3, pady = 15)
        Label(frame, text = 'Export data file(s) to:', font=('Verdana', 10)).grid(row = 0, column = 1)
        self.express = Button(frame, text = '1. Single Worksheet', command = GETexpress, font=('Verdana', 9))
        self.express.grid(row = 1, column = 0, sticky = W, padx = 30)
        self.express.tip = CreateToolTip(self.express, "Export all data to one Excel worksheet in one Excel file")

        self.sheets = Button(frame, text = '2. Separate Sheets', command = GETsheets, font=('Verdana', 9))
        self.sheets.grid(row = 1, column = 1, sticky = W, padx = 30)
        self.sheets.tip = CreateToolTip(self.sheets, "Export each data file to a separate worksheet within the same Excel file")
        
        self.books = Button(frame, text = '3. Separate Books', command = GETbooks, font=('Verdana', 9))
        self.books.grid(row = 1, column = 2, sticky = W, padx = 30)
        self.books.tip = CreateToolTip(self.books, "Export each data file to its own Excel file")

        self.convert = Button(frame, text = 'Convert MRP', command = convertprofile, font=('Verdana', 9))
        self.convert.grid(row = 2, column = 0, sticky = W, padx = 30)
        self.convert.tip = CreateToolTip(self.convert, "Convert an MPC2XL Row Profile into a GEToperant profile")
        self.exit = Button(frame, text = 'Quit', command = quit, font=('Verdana', 9))
        self.exit.grid(row = 2, column = 2, sticky = E, padx = 30, pady = 20)

app = App(root)
root.mainloop()
