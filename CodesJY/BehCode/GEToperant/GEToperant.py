### This program will collected Med PC data files and match them to a data profile for saving to an excel workbook.
### Preconditions: All data files must have the same structure and fit the same profile.
### It is recommended to open either multiple files with single subjects or one file with multiple subjects.
### Where an MSN has not used the Y2KCOMPLIANT command, the data was collected in the 21st century.

import xlrd
import xlsxwriter
import re
import itertools

def convertMRP(GETprofile, profileexport):
    rowprofile = open(GETprofile, 'r').readlines()

    Label = list()
    LabelStartValue = list()
    LabelIncrement = list()
    ArrayVar = list()
    StartElement = list()
    ArrayIncrement = list()
    StopElement = list()

    for i in range(0, len(rowprofile), 2):
        ### For each label in the MRP, decide if it is a data value, if so, then import it
        row_check = re.search(r'\D\(\d+\)', rowprofile[i+1])
        if row_check != None:
            Label.append(rowprofile[i][:-1])
            LabelStartValue.append(None)
            LabelIncrement.append(None)
            ArrayVar.append(rowprofile[i+1][0])
            StartElement.append(int(re.search(r'\d+', rowprofile[i+1]).group(0)))
            ArrayIncrement.append(0)
            StopElement.append(None)
        elif 'comment' in rowprofile[i+1].lower():
            Label.append(rowprofile[i][:-1])
            LabelStartValue.append(None)
            LabelIncrement.append(None)
            ArrayVar.append('Comments')
            StartElement.append(0)
            ArrayIncrement.append(0)
            StopElement.append(None)

    output = xlsxwriter.Workbook(profileexport)
    output.set_properties({
                    'title': 'GEToperant Profile',
                    'subject': 'Animal behaviour',
                    'comments': 'MPC2XL Row Profile converted for use with GEToperant. https://github.com/SKhoo/GEToperant'
                    })

    mainsheet = output.add_worksheet('GEToperant Profile')
    mainsheet.set_column('A:A', 25)
    mainsheet.set_column('B:G', 15)

    mainsheet.write(0, 0, 'Label')
    mainsheet.write(0, 1, 'Label Start Value')
    mainsheet.write(0, 2, 'Label Increment')
    mainsheet.write(0, 3, 'Array/Variable')
    mainsheet.write(0, 4, 'Start Element')
    mainsheet.write(0, 5, 'Increment Element')
    mainsheet.write(0, 6, 'Stop Element')
    mainsheet.write(0, 7, 'Converted file: ' + GETprofile)
    mainsheet.write(1, 7, 'Label tells the program what the name the data point')
    mainsheet.write(2, 7, 'Array/Variable tells the program where to look for the data')
    mainsheet.write(3, 7, 'Start Element tells the program which element to extract for that label')
    mainsheet.write(4, 7, 'Increment Element tells the program if more elements need to be extracted from an array, and if so, whether to collect every element, or every nth element.')
    mainsheet.write(5, 7, 'Stop Element tells the program when to stop extracting elements from an array. It is not needed if only collecting 1 element')
    mainsheet.write(6, 7, 'Label Start Value and Label Increment can be used to increment a label that is used for multiple elements')

    for i in range(len(Label)):
        mainsheet.write(i+1, 0, Label[i])
        mainsheet.write(i+1, 1, LabelStartValue[i])
        mainsheet.write(i+1, 2, LabelIncrement[i])
        mainsheet.write(i+1, 3, ArrayVar[i])
        mainsheet.write(i+1, 4, StartElement[i])
        mainsheet.write(i+1, 5, ArrayIncrement[i])
        mainsheet.write(i+1, 6, StopElement[i])

    output.close()

### The main function

def GEToperant(GETprofile, MPCdatafiles, outputfile,
               exportfilename = 1,
               exportstartdate = 1,
               exportenddate = 1,
               exportsubject = 1,
               exportexperiment = 1,
               exportgroup = 1,
               exportbox = 1,
               exportstarttime = 1,
               exportendtime = 1,
               exportmsn = 1,
               mode = 'Main'):
    '''
    GEToperant takes three main arguments:
    GETprofile, which must be an Excel file
    MPCdatafiles, which must be a list of one or more Med-PC data files
    outputfile, which must be an Excel file

    It takes another 10 arguments relating to what headers to export
    and how to export the data.

    GEToperant will read the data from the MPCdatafiles and will
    output the headers and the data described in GETprofile. It will
    save this in the Excel file specified by outputfile.

    Preconditions: The profile must be a GEToperant profile or MRP.
    If writing to 'Sheets', the file names cannot have illegal characters: ' [ ] : * ? / \ '
    '''


    ### This first part will read the data profile and develop a series of lists
    Label = list()
    LabelStartValue = list()
    LabelIncrement = list()
    ArrayVar = list()
    StartElement = list()
    ArrayIncrement = list()
    StopElement = list()

    if 'xlsx' in GETprofile[-4:].lower():
        ### Import an Excel-based GEToperant profile
        profile_xl = xlrd.open_workbook(GETprofile)
        profile_xl_sheets = profile_xl.sheet_names()
        profilesheet = profile_xl.sheet_by_name(profile_xl_sheets[0])

        for r in range(1,max(range(profilesheet.nrows))+1):
            cell0 = profilesheet.cell(r,0)
            Label.append(str(cell0).split("\'")[1])
            
            cell1 = profilesheet.cell(r,1)
            if 'empty' in str(cell1):
                LabelStartValue.append(None)
            elif 'number' in str(cell1):
                LabelStartValue.append(int(float(str(cell1).split(":")[1])))

            cell2 = profilesheet.cell(r,2)
            if 'empty' in str(cell2):
                LabelIncrement.append(None)
            elif 'number' in str(cell2):
                LabelIncrement.append(int(float(str(cell2).split(":")[1])))

            cell3 = profilesheet.cell(r,3)
            ArrayVar.append(str(cell3).split("\'")[1])

            cell4 = profilesheet.cell(r,4)
            StartElement.append(int(float(str(cell4).split(":")[1])))

            cell5 = profilesheet.cell(r,5)
            if 'empty' in str(cell5):
                ArrayIncrement.append(None)
            elif 'number' in str(cell5):
                ArrayIncrement.append(int(float(str(cell5).split(":")[1])))

            cell6 = profilesheet.cell(r,6)
            if 'empty' in str(cell6) or 'text' in str(cell6):
                StopElement.append(None)
            elif 'number' in str(cell6):
                StopElement.append(int(float(str(cell6).split(":")[1])))

    elif 'mrp' in GETprofile[-3:].lower():
        rowprofile = open(GETprofile, 'r').readlines()
        for i in range(0, len(rowprofile), 2):
            ### For each label in the MRP, decide if it is a data value, if so, then import it
            row_check = re.search(r'\D\(\d+\)', rowprofile[i+1])
            if row_check != None:
                Label.append(rowprofile[i][:-1])
                LabelStartValue.append(None)
                LabelIncrement.append(None)
                ArrayVar.append(rowprofile[i+1][0])
                StartElement.append(int(re.search(r'\d+', rowprofile[i+1]).group(0)))
                ArrayIncrement.append(0)
                StopElement.append(None)
            elif 'comment' in rowprofile[i+1].lower():
                Label.append(rowprofile[i][:-1])
                LabelStartValue.append(None)
                LabelIncrement.append(None)
                ArrayVar.append('Comments')
                StartElement.append(0)
                ArrayIncrement.append(0)
                StopElement.append(None)

    ### The relevant fields in the Med-PC file are then defined as a series of lists
    Filenames = list()
    Startdate = list()
    Enddate = list()
    Subject = list()
    Experiment = list()
    Group = list()
    Box = list()
    Starttime = list()
    Endtime = list()
    MSN = list()
    A = list()
    B = list()
    C = list()
    D = list()
    E = list()
    F = list()
    G = list()
    H = list()
    I = list()
    J = list()
    K = list()
    L = list()
    M = list()
    N = list()
    O = list()
    P = list()
    Q = list()
    R = list()
    S = list()
    T = list()
    U = list()
    V = list()
    W = list()
    X = list()
    Y = list()
    Z = list()
    Comments = list()

    ### The datavars variable holds the names of all the data variables.
    ### It will be used to loop over the arrays at the end of each subject
    ### and even out any length differences
    datavars = list(['A','B','C','D','E','F',
                'G','H','I','J','K','L','M',
                'N','O','P','Q','R','S','T',
                'U','V','W','X','Y','Z'])

    ### Values will hold the numbers for each array so they can be collected and flattened
    values = list()
    currentarray = ''
    shortpath = ''

    if mode == 'Main':
        MPC_filelist = list(MPCdatafiles)
        MPC_file = list()
        for i in MPC_filelist:
            MPC_file.append(open(i, 'r').readlines())

        ### Begin the for loop that will loop over the data and collect everything into MPC_file
        for i in MPC_file:
            for line in i:
                # Begin by collecting the headers
                # Collect the file names
                if 'File' in line:
                    path = line[6:-1]
                    Filenames.append(path)
                    shortpath = line.split('\\')[-1]
                # Collect the start and end dates in ISO 8601 format, correcting for a lack of Y2KCOMPLIANT.
                elif 'Start Date' in line:
                    if len(line) < 22:
                        Startdate.append("20"+line[18:-1]+"-"+line[12:14]+"-"+line[15:17])
                    else:
                        Startdate.append(line[18:-1]+"-"+line[12:14]+"-"+line[15:17])
                    if len(Startdate) > len(Filenames):
                        Filenames.append(shortpath)
                elif 'End Date' in line:
                    if len(line) < 20:
                        Enddate.append("20"+line[16:-1]+"-"+line[10:12]+"-"+line[13:15])
                    else:
                        Enddate.append(line[16:-1]+"-"+line[10:12]+"-"+line[13:15])
                # Similarly, collect subject, experiment, group, box, start time, end time and program name
                elif 'Subject' in line:
                    Subject.append(line[9:-1])
                elif 'Experiment' in line:
                    Experiment.append(line[12:-1])
                elif 'Group' in line:
                    Group.append(line[7:-1])
                elif 'Box' in line:
                    Box.append(line[5:-1])
                elif 'Start Time' in line:
                    if line[12] == ' ':
                        Starttime.append(line[13:-1])
                    else:
                        Starttime.append(line[12:-1])
                elif 'End Time' in line:
                    if line[10] == ' ':
                        Endtime.append(line[11:-1])
                    else:
                        Endtime.append(line[10:-1])
                elif 'MSN' in line:
                    MSN.append(line[5:-1])
                # Check for an array header, if it is present, check if values have been entered into
                # a previous data array. If there are previous data values, flatten the data array and dump them.
                elif len(line) > 1:
                    if re.search(r'\D:', line) != None and line[0:1] != '\\':
                        if len(values) > 0:
                            values = list(itertools.chain.from_iterable(values))
                            eval(currentarray).append(values)
                            values = list()
                        ### here we should check for whether the letter has been printed as just a variable.
                        if re.search(r'\d', line) != None and line[0:1] != '\\':
                            currentarray = line[0]
                            values.append(line.split()[1])
                            eval(currentarray).append(values)
                            values = list()
                        ### then we should set the beginning of a new array.
                        else:
                            currentarray = line[0]
                    ### this part checks if the line is a comment and then collects the data
                    elif line[0:1] == '\\':
                        if len(values) > 0:
                            values = list(itertools.chain.from_iterable(values))
                            eval(currentarray).append(values)
                            values = list()
                            Comments.append(line[1:-1])
                        else:
                            Comments.append(line[1:-1])
                    else:
                        values.append(line.split()[1:])
                elif line == '\n' or len(line) < 1:
                    if len(values) > 0:
                        values = list(itertools.chain.from_iterable(values))
                        eval(currentarray).append(values)
                        values = list()
                    if len(Startdate) > len(Comments):
                        Comments.append(None)
                    for v in datavars:
                        if len(eval(v)) < len(Startdate):
                            eval(v).append(list())

        ### Check to see if the for loop has ended on a line with values.
        ### Tie off the loose ends
        if len(line) > 1:
            if len(values) > 0:
                values = list(itertools.chain.from_iterable(values))
                eval(currentarray).append(values)
                values = list()
            if len(Startdate) > len(Comments):
                Comments.append(None)
            for v in datavars:
                if len(eval(v)) < len(Startdate):
                    eval(v).append(list())


        ### This final part will begin writing the data to the Excel file.
        output = xlsxwriter.Workbook(outputfile)
        output.set_properties({
            'title': 'Med-PC Data',
            'subject': 'Animal behaviour',
            'category': 'Raw data',
            'comments': 'Extracted using GEToperant. GEToperant is free open source software. https://www.github.com/SKhoo'
            })

        mainsheet = output.add_worksheet('GEToperant output')

        ### Write the headers
        mainsheet.set_column('A:A', 15)

        lastrow = -1

        if exportfilename == 1:
            lastrow = lastrow + 1
            mainsheet.write(lastrow, 0, 'Filename')
            for i in range(len(Filenames)):
                mainsheet.write(lastrow, i+1, Filenames[i])

        if exportstartdate == 1:
            lastrow = lastrow + 1
            mainsheet.write(lastrow, 0, 'Start Date')
            for i in range(len(Startdate)):
                mainsheet.write(lastrow, i+1, Startdate[i])

        if exportenddate == 1:
            lastrow = lastrow + 1
            mainsheet.write(lastrow, 0, 'End Date')
            for i in range(len(Enddate)):
                mainsheet.write(lastrow, i+1, Enddate[i])

        if exportsubject == 1:
            lastrow = lastrow + 1
            mainsheet.write(lastrow, 0, 'Subject')
            for i in range(len(Subject)):
                mainsheet.write(lastrow, i+1, Subject[i])

        if exportexperiment == 1:
            lastrow = lastrow + 1
            mainsheet.write(lastrow, 0, 'Experiment')
            for i in range(len(Subject)):
                mainsheet.write(lastrow, i+1, Experiment[i])

        if exportgroup == 1:
            lastrow = lastrow + 1
            mainsheet.write(lastrow, 0, 'Group')
            for i in range(len(Group)):
                mainsheet.write(lastrow, i+1, Group[i])

        if exportbox == 1:
            lastrow = lastrow + 1
            mainsheet.write(lastrow, 0, 'Box')
            for i in range(len(Box)):
                mainsheet.write(lastrow, i+1, float(Box[i]))

        if exportstarttime == 1:
            lastrow = lastrow + 1
            mainsheet.write(lastrow, 0, 'Start Time')
            for i in range(len(Starttime)):
                mainsheet.write(lastrow, i+1, Starttime[i])

        if exportendtime == 1:
            lastrow = lastrow + 1
            mainsheet.write(lastrow, 0, 'End Time')
            for i in range(len(Endtime)):
                mainsheet.write(lastrow, i+1, Endtime[i])

        if exportmsn == 1:
            lastrow = lastrow + 1
            mainsheet.write(lastrow, 0, 'MSN')
            for i in range(len(MSN)):
                mainsheet.write(lastrow, i+1, MSN[i])

        for i in range(len(Label)):
            ### This function will loop over the profile. For each label it will check if it is
            ### 1. A single element extraction
            ### 2. A partial array extraction
            ### 3. A full array extraction
            if ArrayIncrement[i] < 1:
                # Single element extraction takes only the label
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, Label[i])
                if 'comment' in ArrayVar[i].lower():
                    for k in range(len(Subject)):
                        if k < len(Comments):
                            mainsheet.write(lastrow, k+1, Comments[k])
                        else:
                            mainsheet.write(lastrow, k+1, None)
                else:
                    for k in range(len(Subject)):
                        if len(eval(ArrayVar[i])) > 0 and StartElement[i] < len(eval(ArrayVar[i])[k]):
                            mainsheet.write(lastrow, k+1, float(eval(ArrayVar[i])[k][StartElement[i]]))
                        else:
                            mainsheet.write(lastrow, k+1, None)
            elif ArrayIncrement[i] > 0:
                if StopElement[i] == None or isinstance(StopElement[i], str):
                    steps = range(StartElement[i], len(max(eval(ArrayVar[i]), key = len)), ArrayIncrement[i])
                elif StopElement[i] > StartElement[i]:
                    if len(max(eval(ArrayVar[i]), key = len)) < StopElement[i] + 1:
                        steps = range(StartElement[i], len(max(eval(ArrayVar[i]), key = len)), ArrayIncrement[i])
                    else:
                        steps = range(StartElement[i], StopElement[i] + 1, ArrayIncrement[i])
                for x in steps:
                    lastrow = lastrow + 1
                    for k in range(len(Subject)):
                        if LabelIncrement[i] != None and LabelIncrement[i] > 0:
                            mainsheet.write(lastrow, 0, Label[i] + ' ' + str(LabelStartValue[i] + int((x-StartElement[i])/ArrayIncrement[i]) * LabelIncrement[i]))
                        else:
                            mainsheet.write(lastrow, 0, Label[i])
                        if x < len(eval(ArrayVar[i])[k]):
                            mainsheet.write(lastrow, k+1, float(eval(ArrayVar[i])[k][x]))
                        else:
                            mainsheet.write(lastrow, k+1, None)

        output.close()

    elif mode == 'Sheets':
        MPC_filelist = MPCdatafiles

        output = xlsxwriter.Workbook(outputfile)
        output.set_properties({
                'title': 'Med-PC Data',
                'subject': 'Animal behaviour',
                'category': 'Raw data',
                'comments': 'Extracted using GEToperant. GEToperant is free open source software. https://www.github.com/SKhoo'
                })
        
        for dfile in MPC_filelist:
            ### Get the filename and use it for the sheet
            ### If the filename is 32 characters or longer, shorten it
            MPC_file = open(dfile, 'r').readlines()
            sheetname = dfile.split('/')[-1]
            if len(sheetname) >= 32:
                sheetname = sheetname[:31]
       
            ### The relevant fields in the Med-PC file are then defined as a series of lists
            Filenames = list()
            Startdate = list()
            Enddate = list()
            Subject = list()
            Experiment = list()
            Group = list()
            Box = list()
            Starttime = list()
            Endtime = list()
            MSN = list()
            A = list()
            B = list()
            C = list()
            D = list()
            E = list()
            F = list()
            G = list()
            H = list()
            I = list()
            J = list()
            K = list()
            L = list()
            M = list()
            N = list()
            O = list()
            P = list()
            Q = list()
            R = list()
            S = list()
            T = list()
            U = list()
            V = list()
            W = list()
            X = list()
            Y = list()
            Z = list()
            Comments = list()

            ### The datavars variable holds the names of all the data variables.
            ### It will be used to loop over the arrays at the end of each subject
            ### and even out any length differences
            datavars = list(['A','B','C','D','E','F',
                        'G','H','I','J','K','L','M',
                        'N','O','P','Q','R','S','T',
                        'U','V','W','X','Y','Z'])

            ### Values will hold the numbers for each array so they can be collected and flattened
            values = list()
            currentarray = ''

            

            ### Begin the for loop that will loop over the data and collect everything into MPC_file
            for line in MPC_file:
                # Begin by collecting the headers
                # Collect the file names
                if 'File' in line:
                    path = line[6:-1]
                    Filenames.append(path)
                # Collect the start and end dates in ISO 8601 format, correcting for a lack of Y2KCOMPLIANT.
                elif 'Start Date' in line:
                    if len(line) < 22:
                        Startdate.append("20"+line[18:-1]+"-"+line[12:14]+"-"+line[15:17])
                    else:
                        Startdate.append(line[18:-1]+"-"+line[12:14]+"-"+line[15:17])
                    if len(Startdate) > len(Filenames):
                        Filenames.append(None)
                elif 'End Date' in line:
                    if len(line) < 20:
                        Enddate.append("20"+line[16:-1]+"-"+line[10:12]+"-"+line[13:15])
                    else:
                        Enddate.append(line[16:-1]+"-"+line[10:12]+"-"+line[13:15])
                # Similarly, collect subject, experiment, group, box, start time, end time and program name
                elif 'Subject' in line:
                    Subject.append(line[9:-1])
                elif 'Experiment' in line:
                    Experiment.append(line[12:-1])
                elif 'Group' in line:
                    Group.append(line[7:-1])
                elif 'Box' in line:
                    Box.append(line[5:-1])
                elif 'Start Time' in line:
                    if line[12] == ' ':
                        Starttime.append(line[13:-1])
                    else:
                        Starttime.append(line[12:-1])
                elif 'End Time' in line:
                    if line[10] == ' ':
                        Endtime.append(line[11:-1])
                    else:
                        Endtime.append(line[10:-1])
                elif 'MSN' in line:
                    MSN.append(line[5:-1])
                # Check for an array header, if it is present, check if values have been entered into
                # a previous data array. If there are previous data values, flatten the data array and dump them.
                elif len(line) > 1:
                    if re.search(r'\D:', line) != None and line[0:1] != '\\':
                        if len(values) > 0:
                            values = list(itertools.chain.from_iterable(values))
                            eval(currentarray).append(values)
                            values = list()
                        ### here we should check for whether the letter has been printed as just a variable.
                        if re.search(r'\d', line) != None and line[0:1] != '\\':
                            currentarray = line[0]
                            values.append(line.split()[1])
                            eval(currentarray).append(values)
                            values = list()
                        ### then we should set the beginning of a new array.
                        else:
                            currentarray = line[0]
                    ### this part checks if the line is a comment and then collects the data
                    elif line[0:1] == '\\':
                        if len(values) > 0:
                            values = list(itertools.chain.from_iterable(values))
                            eval(currentarray).append(values)
                            values = list()
                            Comments.append(line[1:-1])
                        else:
                            Comments.append(line[1:-1])
                    else:
                        values.append(line.split()[1:])
                elif line == '\n' or len(line) < 1:
                    if len(values) > 0:
                        values = list(itertools.chain.from_iterable(values))
                        eval(currentarray).append(values)
                        values = list()
                    if len(Startdate) > len(Comments):
                        Comments.append(None)
                    for v in datavars:
                        if len(eval(v)) < len(Startdate):
                            eval(v).append(list())

            ### Check to see if the for loop has ended on a line with values.
            ### Tie off the loose ends
            if len(line) > 1:
                if len(values) > 0:
                    values = list(itertools.chain.from_iterable(values))
                    eval(currentarray).append(values)
                    values = list()
                if len(Startdate) > len(Comments):
                    Comments.append(None)
                for v in datavars:
                    if len(eval(v)) < len(Startdate):
                        eval(v).append(list())


                ### This final part will begin writing the data to the Excel file.


            mainsheet = output.add_worksheet(sheetname)

            ### Write the headers
            mainsheet.set_column('A:A', 15)

            lastrow = -1

            if exportfilename == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Filename')
                for i in range(len(Filenames)):
                    mainsheet.write(lastrow, i+1, Filenames[i])

            if exportstartdate == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Start Date')
                for i in range(len(Startdate)):
                    mainsheet.write(lastrow, i+1, Startdate[i])

            if exportenddate == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'End Date')
                for i in range(len(Enddate)):
                    mainsheet.write(lastrow, i+1, Enddate[i])

            if exportsubject == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Subject')
                for i in range(len(Subject)):
                    mainsheet.write(lastrow, i+1, Subject[i])

            if exportexperiment == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Experiment')
                for i in range(len(Subject)):
                    mainsheet.write(lastrow, i+1, Experiment[i])

            if exportgroup == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Group')
                for i in range(len(Group)):
                    mainsheet.write(lastrow, i+1, Group[i])

            if exportbox == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Box')
                for i in range(len(Box)):
                    mainsheet.write(lastrow, i+1, float(Box[i]))

            if exportstarttime == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Start Time')
                for i in range(len(Starttime)):
                    mainsheet.write(lastrow, i+1, Starttime[i])

            if exportendtime == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'End Time')
                for i in range(len(Endtime)):
                    mainsheet.write(lastrow, i+1, Endtime[i])

            if exportmsn == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'MSN')
                for i in range(len(MSN)):
                    mainsheet.write(lastrow, i+1, MSN[i])

            for i in range(len(Label)):
                ### This function will loop over the profile. For each label it will check if it is
                ### 1. A single element extraction
                ### 2. A partial array extraction
                ### 3. A full array extraction
                if ArrayIncrement[i] < 1:
                    # Single element extraction takes only the label
                    lastrow = lastrow + 1
                    mainsheet.write(lastrow, 0, Label[i])
                    if 'comment' in ArrayVar[i].lower():
                        for k in range(len(Subject)):
                            if k < len(Comments):
                                mainsheet.write(lastrow, k+1, Comments[k])
                            else:
                                mainsheet.write(lastrow, k+1, None)
                    else:
                        for k in range(len(Subject)):
                            if len(eval(ArrayVar[i])) > 0 and StartElement[i] < len(eval(ArrayVar[i])[k]):
                                mainsheet.write(lastrow, k+1, float(eval(ArrayVar[i])[k][StartElement[i]]))
                            else:
                                mainsheet.write(lastrow, k+1, None)
                elif ArrayIncrement[i] > 0:
                    if StopElement[i] == None or isinstance(StopElement[i], str):
                        steps = range(StartElement[i], len(max(eval(ArrayVar[i]), key = len)), ArrayIncrement[i])
                    elif StopElement[i] > StartElement[i]:
                        if len(max(eval(ArrayVar[i]), key = len)) < StopElement[i] + 1:
                            steps = range(StartElement[i], len(max(eval(ArrayVar[i]), key = len)), ArrayIncrement[i])
                        else:
                            steps = range(StartElement[i], StopElement[i] + 1, ArrayIncrement[i])
                    for x in steps:
                        lastrow = lastrow + 1
                        for k in range(len(Subject)):
                            if LabelIncrement[i] != None and LabelIncrement[i] > 0:
                                mainsheet.write(lastrow, 0, Label[i] + ' ' + str(LabelStartValue[i] + int((x-StartElement[i])/ArrayIncrement[i]) * LabelIncrement[i]))
                            else:
                                mainsheet.write(lastrow, 0, Label[i])
                            if x < len(eval(ArrayVar[i])[k]):
                                mainsheet.write(lastrow, k+1, float(eval(ArrayVar[i])[k][x]))
                            else:
                                mainsheet.write(lastrow, k+1, None)

        output.close()

    elif mode == 'Books':
        MPC_filelist = MPCdatafiles
        for dfile in MPC_filelist:
            xlsxfilename = dfile.split('/')[-1]
            MPC_file = open(dfile, 'r').readlines()
            
            Filenames = list()
            Startdate = list()
            Enddate = list()
            Subject = list()
            Experiment = list()
            Group = list()
            Box = list()
            Starttime = list()
            Endtime = list()
            MSN = list()
            A = list()
            B = list()
            C = list()
            D = list()
            E = list()
            F = list()
            G = list()
            H = list()
            I = list()
            J = list()
            K = list()
            L = list()
            M = list()
            N = list()
            O = list()
            P = list()
            Q = list()
            R = list()
            S = list()
            T = list()
            U = list()
            V = list()
            W = list()
            X = list()
            Y = list()
            Z = list()
            Comments = list()

            ### The datavars variable holds the names of all the data variables.
            ### It will be used to loop over the arrays at the end of each subject
            ### and even out any length differences
            datavars = list(['A','B','C','D','E','F',
                        'G','H','I','J','K','L','M',
                        'N','O','P','Q','R','S','T',
                        'U','V','W','X','Y','Z'])

            ### Values will hold the numbers for each array so they can be collected and flattened
            values = list()
            currentarray = ''

            

            ### Begin the for loop that will loop over the data and collect everything into MPC_file
            for line in MPC_file:
                # Begin by collecting the headers
                # Collect the file names
                if 'File' in line:
                    path = line[6:-1]
                    Filenames.append(path)
                # Collect the start and end dates in ISO 8601 format, correcting for a lack of Y2KCOMPLIANT.
                elif 'Start Date' in line:
                    if len(line) < 22:
                        Startdate.append("20"+line[18:-1]+"-"+line[12:14]+"-"+line[15:17])
                    else:
                        Startdate.append(line[18:-1]+"-"+line[12:14]+"-"+line[15:17])
                    if len(Startdate) > len(Filenames):
                        Filenames.append(None)
                elif 'End Date' in line:
                    if len(line) < 20:
                        Enddate.append("20"+line[16:-1]+"-"+line[10:12]+"-"+line[13:15])
                    else:
                        Enddate.append(line[16:-1]+"-"+line[10:12]+"-"+line[13:15])
                # Similarly, collect subject, experiment, group, box, start time, end time and program name
                elif 'Subject' in line:
                    Subject.append(line[9:-1])
                elif 'Experiment' in line:
                    Experiment.append(line[12:-1])
                elif 'Group' in line:
                    Group.append(line[7:-1])
                elif 'Box' in line:
                    Box.append(line[5:-1])
                elif 'Start Time' in line:
                    if line[12] == ' ':
                        Starttime.append(line[13:-1])
                    else:
                        Starttime.append(line[12:-1])
                elif 'End Time' in line:
                    if line[10] == ' ':
                        Endtime.append(line[11:-1])
                    else:
                        Endtime.append(line[10:-1])
                elif 'MSN' in line:
                    MSN.append(line[5:-1])
                # Check for an array header, if it is present, check if values have been entered into
                # a previous data array. If there are previous data values, flatten the data array and dump them.
                elif len(line) > 1:
                    if re.search(r'\D:', line) != None and line[0:1] != '\\':
                        if len(values) > 0:
                            values = list(itertools.chain.from_iterable(values))
                            eval(currentarray).append(values)
                            values = list()
                        ### here we should check for whether the letter has been printed as just a variable.
                        if re.search(r'\d', line) != None and line[0:1] != '\\':
                            currentarray = line[0]
                            values.append(line.split()[1])
                            eval(currentarray).append(values)
                            values = list()
                        ### then we should set the beginning of a new array.
                        else:
                            currentarray = line[0]
                    ### this part checks if the line is a comment and then collects the data
                    elif line[0:1] == '\\':
                        if len(values) > 0:
                            values = list(itertools.chain.from_iterable(values))
                            eval(currentarray).append(values)
                            values = list()
                            Comments.append(line[1:-1])
                        else:
                            Comments.append(line[1:-1])
                    else:
                        values.append(line.split()[1:])
                elif line == '\n' or len(line) < 1:
                    if len(values) > 0:
                        values = list(itertools.chain.from_iterable(values))
                        eval(currentarray).append(values)
                        values = list()
                    if len(Startdate) > len(Comments):
                        Comments.append(None)
                    for v in datavars:
                        if len(eval(v)) < len(Startdate):
                            eval(v).append(list())

            ### Check to see if the for loop has ended on a line with values.
            ### Tie off the loose ends
            if len(line) > 1:
                if len(values) > 0:
                    values = list(itertools.chain.from_iterable(values))
                    eval(currentarray).append(values)
                    values = list()
                if len(Startdate) > len(Comments):
                    Comments.append(None)
                for v in datavars:
                    if len(eval(v)) < len(Startdate):
                        eval(v).append(list())


            ### This final part will begin writing the data to the Excel file.

            fullpath = outputfile + '/' + xlsxfilename + '.xlsx'

            output = xlsxwriter.Workbook(fullpath)
            output.set_properties({
                'title': 'Med-PC Data',
                'subject': 'Animal behaviour',
                'category': 'Raw data',
                'comments': 'Extracted using GEToperant. GEToperant is free open source software. https://www.github.com/SKhoo'
                })

            mainsheet = output.add_worksheet('GEToperant output')

            ### Write the headers
            mainsheet.set_column('A:A', 15)

            lastrow = -1

            if exportfilename == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Filename')
                for i in range(len(Filenames)):
                    mainsheet.write(lastrow, i+1, Filenames[i])

            if exportstartdate == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Start Date')
                for i in range(len(Startdate)):
                    mainsheet.write(lastrow, i+1, Startdate[i])

            if exportenddate == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'End Date')
                for i in range(len(Enddate)):
                    mainsheet.write(lastrow, i+1, Enddate[i])

            if exportsubject == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Subject')
                for i in range(len(Subject)):
                    mainsheet.write(lastrow, i+1, Subject[i])

            if exportexperiment == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Experiment')
                for i in range(len(Subject)):
                    mainsheet.write(lastrow, i+1, Experiment[i])

            if exportgroup == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Group')
                for i in range(len(Group)):
                    mainsheet.write(lastrow, i+1, Group[i])

            if exportbox == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Box')
                for i in range(len(Box)):
                    mainsheet.write(lastrow, i+1, float(Box[i]))

            if exportstarttime == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'Start Time')
                for i in range(len(Starttime)):
                    mainsheet.write(lastrow, i+1, Starttime[i])

            if exportendtime == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'End Time')
                for i in range(len(Endtime)):
                    mainsheet.write(lastrow, i+1, Endtime[i])

            if exportmsn == 1:
                lastrow = lastrow + 1
                mainsheet.write(lastrow, 0, 'MSN')
                for i in range(len(MSN)):
                    mainsheet.write(lastrow, i+1, MSN[i])

            for i in range(len(Label)):
                ### This function will loop over the profile. For each label it will check if it is
                ### 1. A single element extraction
                ### 2. A partial array extraction
                ### 3. A full array extraction
                if ArrayIncrement[i] < 1:
                    # Single element extraction takes only the label
                    lastrow = lastrow + 1
                    mainsheet.write(lastrow, 0, Label[i])
                    if 'comment' in ArrayVar[i].lower():
                        for k in range(len(Subject)):
                            if k < len(Comments):
                                mainsheet.write(lastrow, k+1, Comments[k])
                            else:
                                mainsheet.write(lastrow, k+1, None)
                    else:
                        for k in range(len(Subject)):
                            if len(eval(ArrayVar[i])) > 0 and StartElement[i] < len(eval(ArrayVar[i])[k]):
                                mainsheet.write(lastrow, k+1, float(eval(ArrayVar[i])[k][StartElement[i]]))
                            else:
                                mainsheet.write(lastrow, k+1, None)
                elif ArrayIncrement[i] > 0:
                    if StopElement[i] == None or isinstance(StopElement[i], str):
                        steps = range(StartElement[i], len(max(eval(ArrayVar[i]), key = len)), ArrayIncrement[i])
                    elif StopElement[i] > StartElement[i]:
                        if len(max(eval(ArrayVar[i]), key = len)) < StopElement[i] + 1:
                            steps = range(StartElement[i], len(max(eval(ArrayVar[i]), key = len)), ArrayIncrement[i])
                        else:
                            steps = range(StartElement[i], StopElement[i] + 1, ArrayIncrement[i])
                    for x in steps:
                        lastrow = lastrow + 1
                        for k in range(len(Subject)):
                            if LabelIncrement[i] != None and LabelIncrement[i] > 0:
                                mainsheet.write(lastrow, 0, Label[i] + ' ' + str(LabelStartValue[i] + int((x-StartElement[i])/ArrayIncrement[i]) * LabelIncrement[i]))
                            else:
                                mainsheet.write(lastrow, 0, Label[i])
                            if x < len(eval(ArrayVar[i])[k]):
                                mainsheet.write(lastrow, k+1, float(eval(ArrayVar[i])[k][x]))
                            else:
                                mainsheet.write(lastrow, k+1, None)

            output.close()
