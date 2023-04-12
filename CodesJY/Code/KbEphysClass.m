classdef KbEphysClass
    %UNTITLED2 Summary of this class goes here
    %   This class function takes r and makes it a class 
    %   This class allows quick plotting of PSTH, etc. 

    properties
        Subject
        Experimenter
        Date
        SampleRate
        DataFiles
        DataDurationSec
        BehaviorLabels
        BehaviorTimings

    end

    properties (Constant)
        BehaviorTimingsUnit = 'ms'
    end


    methods
        function obj = KbEphysClass(r)
            % it takes r and build class
            % 1. Get basic meta data information
            obj.Subject                                 =             r.Meta(1).Subject;
            obj.Experimenter                      =             r.Meta(1).Experimenter;
            obj.Date                                      =             r.Meta(1).DateTime(1:11);
            obj.SampleRate                          =             r.Meta(1).SampleRes;
            obj.DataFiles                                =             arrayfun(@(x)x.Filename, r.Meta, 'UniformOutput', false);
            obj.DataDurationSec                   =              cell2mat(arrayfun(@(x)x.DataDurationSec, r.Meta, 'UniformOutput', false));
            obj.BehaviorLabels                      =             r.Behavior.Labels;
            for i =1:length(obj.BehaviorLabels)
                obj.BehaviorTimings{i}          = r.Behavior.EventTimings(r.Behavior.EventMarkers == i);
            end;
 
        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end