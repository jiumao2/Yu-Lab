function map = viridis(N)
% MatPlotLib 3.3 ��ɫ����
% ����:
% N   -  ����colormap���ȵ�������N>=0������Ϊ�գ���Ϊ��ǰͼ��colormap����
%
% ���:
% map -  Nx3��RGB��ɫ����
%
% Copyright  2020   Akun
% https://zhuanlan.zhihu.com/c_1074615528869531648

if nargin<1 || isempty(N)
	N = size(get(gcf,'colormap'),1);
else
	assert(isscalar(N)&&isreal(N),'First argument must be a real numeric scalar.')
end

C = [0.266666666666667,0.00392156862745098,0.329411764705882;0.266666666666667,0.00784313725490196,0.333333333333333;0.266666666666667,0.0117647058823529,0.341176470588235;0.270588235294118,0.0235294117647059,0.352941176470588;0.270588235294118,0.0313725490196078,0.356862745098039;0.274509803921569,0.0352941176470588,0.360784313725490;0.274509803921569,0.0431372549019608,0.368627450980392;0.274509803921569,0.0470588235294118,0.372549019607843;0.274509803921569,0.0549019607843137,0.380392156862745;0.278431372549020,0.0588235294117647,0.384313725490196;0.278431372549020,0.0705882352941177,0.396078431372549;0.278431372549020,0.0784313725490196,0.400000000000000;0.278431372549020,0.0823529411764706,0.403921568627451;0.278431372549020,0.0862745098039216,0.411764705882353;0.278431372549020,0.0941176470588235,0.415686274509804;0.282352941176471,0.0980392156862745,0.419607843137255;0.282352941176471,0.101960784313725,0.423529411764706;0.282352941176471,0.113725490196078,0.435294117647059;0.282352941176471,0.117647058823529,0.439215686274510;0.282352941176471,0.125490196078431,0.443137254901961;0.282352941176471,0.129411764705882,0.447058823529412;0.282352941176471,0.133333333333333,0.450980392156863;0.282352941176471,0.137254901960784,0.454901960784314;0.278431372549020,0.145098039215686,0.458823529411765;0.278431372549020,0.152941176470588,0.466666666666667;0.278431372549020,0.156862745098039,0.470588235294118;0.278431372549020,0.164705882352941,0.474509803921569;0.278431372549020,0.168627450980392,0.478431372549020;0.278431372549020,0.172549019607843,0.482352941176471;0.274509803921569,0.176470588235294,0.486274509803922;0.274509803921569,0.184313725490196,0.486274509803922;0.274509803921569,0.192156862745098,0.494117647058824;0.270588235294118,0.196078431372549,0.498039215686275;0.270588235294118,0.203921568627451,0.498039215686275;0.270588235294118,0.207843137254902,0.501960784313726;0.270588235294118,0.211764705882353,0.505882352941176;0.266666666666667,0.215686274509804,0.505882352941176;0.262745098039216,0.223529411764706,0.509803921568627;0.262745098039216,0.231372549019608,0.513725490196078;0.262745098039216,0.235294117647059,0.517647058823530;0.258823529411765,0.239215686274510,0.517647058823530;0.258823529411765,0.243137254901961,0.521568627450980;0.258823529411765,0.250980392156863,0.521568627450980;0.254901960784314,0.254901960784314,0.525490196078431;0.250980392156863,0.258823529411765,0.525490196078431;0.250980392156863,0.266666666666667,0.529411764705882;0.247058823529412,0.270588235294118,0.529411764705882;0.247058823529412,0.278431372549020,0.533333333333333;0.243137254901961,0.282352941176471,0.533333333333333;0.243137254901961,0.286274509803922,0.537254901960784;0.239215686274510,0.290196078431373,0.537254901960784;0.239215686274510,0.294117647058824,0.537254901960784;0.235294117647059,0.301960784313725,0.541176470588235;0.235294117647059,0.305882352941177,0.541176470588235;0.231372549019608,0.313725490196078,0.541176470588235;0.231372549019608,0.317647058823529,0.541176470588235;0.227450980392157,0.321568627450980,0.545098039215686;0.223529411764706,0.325490196078431,0.545098039215686;0.223529411764706,0.333333333333333,0.545098039215686;0.219607843137255,0.337254901960784,0.545098039215686;0.219607843137255,0.341176470588235,0.549019607843137;0.215686274509804,0.345098039215686,0.549019607843137;0.215686274509804,0.349019607843137,0.549019607843137;0.211764705882353,0.352941176470588,0.549019607843137;0.207843137254902,0.356862745098039,0.549019607843137;0.207843137254902,0.364705882352941,0.549019607843137;0.203921568627451,0.368627450980392,0.552941176470588;0.203921568627451,0.372549019607843,0.552941176470588;0.200000000000000,0.376470588235294,0.552941176470588;0.200000000000000,0.380392156862745,0.552941176470588;0.196078431372549,0.384313725490196,0.552941176470588;0.192156862745098,0.392156862745098,0.552941176470588;0.192156862745098,0.396078431372549,0.552941176470588;0.192156862745098,0.400000000000000,0.552941176470588;0.188235294117647,0.403921568627451,0.552941176470588;0.188235294117647,0.407843137254902,0.552941176470588;0.184313725490196,0.411764705882353,0.552941176470588;0.184313725490196,0.415686274509804,0.552941176470588;0.180392156862745,0.423529411764706,0.556862745098039;0.180392156862745,0.427450980392157,0.556862745098039;0.176470588235294,0.431372549019608,0.556862745098039;0.176470588235294,0.435294117647059,0.556862745098039;0.172549019607843,0.439215686274510,0.556862745098039;0.172549019607843,0.443137254901961,0.556862745098039;0.172549019607843,0.447058823529412,0.556862745098039;0.168627450980392,0.454901960784314,0.556862745098039;0.164705882352941,0.458823529411765,0.556862745098039;0.164705882352941,0.462745098039216,0.556862745098039;0.164705882352941,0.466666666666667,0.556862745098039;0.160784313725490,0.470588235294118,0.556862745098039;0.160784313725490,0.474509803921569,0.556862745098039;0.156862745098039,0.478431372549020,0.556862745098039;0.156862745098039,0.482352941176471,0.556862745098039;0.152941176470588,0.486274509803922,0.556862745098039;0.152941176470588,0.490196078431373,0.556862745098039;0.152941176470588,0.494117647058824,0.556862745098039;0.149019607843137,0.498039215686275,0.556862745098039;0.149019607843137,0.501960784313726,0.556862745098039;0.149019607843137,0.505882352941176,0.556862745098039;0.145098039215686,0.513725490196078,0.552941176470588;0.141176470588235,0.517647058823530,0.552941176470588;0.141176470588235,0.521568627450980,0.552941176470588;0.141176470588235,0.525490196078431,0.552941176470588;0.137254901960784,0.529411764705882,0.552941176470588;0.137254901960784,0.533333333333333,0.552941176470588;0.133333333333333,0.537254901960784,0.552941176470588;0.133333333333333,0.541176470588235,0.552941176470588;0.133333333333333,0.545098039215686,0.552941176470588;0.129411764705882,0.549019607843137,0.552941176470588;0.129411764705882,0.552941176470588,0.549019607843137;0.129411764705882,0.556862745098039,0.549019607843137;0.125490196078431,0.560784313725490,0.549019607843137;0.125490196078431,0.564705882352941,0.549019607843137;0.121568627450980,0.572549019607843,0.549019607843137;0.121568627450980,0.576470588235294,0.545098039215686;0.121568627450980,0.580392156862745,0.545098039215686;0.121568627450980,0.584313725490196,0.545098039215686;0.121568627450980,0.588235294117647,0.545098039215686;0.117647058823529,0.592156862745098,0.541176470588235;0.117647058823529,0.596078431372549,0.541176470588235;0.117647058823529,0.600000000000000,0.541176470588235;0.117647058823529,0.603921568627451,0.537254901960784;0.117647058823529,0.607843137254902,0.537254901960784;0.117647058823529,0.611764705882353,0.537254901960784;0.117647058823529,0.615686274509804,0.533333333333333;0.117647058823529,0.619607843137255,0.533333333333333;0.117647058823529,0.627450980392157,0.529411764705882;0.121568627450980,0.631372549019608,0.529411764705882;0.121568627450980,0.635294117647059,0.525490196078431;0.121568627450980,0.639215686274510,0.525490196078431;0.125490196078431,0.643137254901961,0.521568627450980;0.125490196078431,0.647058823529412,0.521568627450980;0.129411764705882,0.650980392156863,0.517647058823530;0.133333333333333,0.654901960784314,0.517647058823530;0.137254901960784,0.658823529411765,0.513725490196078;0.137254901960784,0.662745098039216,0.509803921568627;0.141176470588235,0.666666666666667,0.509803921568627;0.145098039215686,0.670588235294118,0.505882352941176;0.149019607843137,0.674509803921569,0.505882352941176;0.152941176470588,0.678431372549020,0.498039215686275;0.160784313725490,0.686274509803922,0.498039215686275;0.164705882352941,0.690196078431373,0.494117647058824;0.168627450980392,0.694117647058824,0.490196078431373;0.172549019607843,0.694117647058824,0.490196078431373;0.180392156862745,0.698039215686275,0.486274509803922;0.184313725490196,0.701960784313725,0.482352941176471;0.196078431372549,0.709803921568628,0.478431372549020;0.200000000000000,0.713725490196078,0.474509803921569;0.207843137254902,0.717647058823529,0.470588235294118;0.211764705882353,0.721568627450980,0.466666666666667;0.219607843137255,0.725490196078431,0.462745098039216;0.223529411764706,0.725490196078431,0.462745098039216;0.231372549019608,0.729411764705882,0.458823529411765;0.243137254901961,0.737254901960784,0.450980392156863;0.250980392156863,0.741176470588235,0.447058823529412;0.258823529411765,0.745098039215686,0.443137254901961;0.266666666666667,0.745098039215686,0.439215686274510;0.270588235294118,0.749019607843137,0.435294117647059;0.278431372549020,0.752941176470588,0.431372549019608;0.286274509803922,0.756862745098039,0.427450980392157;0.301960784313725,0.760784313725490,0.419607843137255;0.309803921568627,0.764705882352941,0.411764705882353;0.317647058823529,0.768627450980392,0.407843137254902;0.325490196078431,0.772549019607843,0.403921568627451;0.333333333333333,0.776470588235294,0.400000000000000;0.341176470588235,0.776470588235294,0.396078431372549;0.349019607843137,0.780392156862745,0.392156862745098;0.368627450980392,0.788235294117647,0.380392156862745;0.376470588235294,0.788235294117647,0.376470588235294;0.384313725490196,0.792156862745098,0.372549019607843;0.392156862745098,0.796078431372549,0.364705882352941;0.403921568627451,0.800000000000000,0.360784313725490;0.411764705882353,0.800000000000000,0.356862745098039;0.423529411764706,0.803921568627451,0.345098039215686;0.439215686274510,0.807843137254902,0.337254901960784;0.447058823529412,0.811764705882353,0.333333333333333;0.454901960784314,0.815686274509804,0.329411764705882;0.466666666666667,0.815686274509804,0.321568627450980;0.474509803921569,0.819607843137255,0.317647058823529;0.486274509803922,0.823529411764706,0.309803921568627;0.498039215686275,0.823529411764706,0.301960784313725;0.513725490196078,0.827450980392157,0.294117647058824;0.525490196078431,0.831372549019608,0.286274509803922;0.533333333333333,0.835294117647059,0.278431372549020;0.545098039215686,0.835294117647059,0.274509803921569;0.552941176470588,0.839215686274510,0.266666666666667;0.564705882352941,0.839215686274510,0.262745098039216;0.576470588235294,0.843137254901961,0.250980392156863;0.592156862745098,0.847058823529412,0.243137254901961;0.603921568627451,0.847058823529412,0.235294117647059;0.615686274509804,0.850980392156863,0.227450980392157;0.623529411764706,0.850980392156863,0.219607843137255;0.635294117647059,0.854901960784314,0.215686274509804;0.650980392156863,0.854901960784314,0.203921568627451;0.666666666666667,0.858823529411765,0.196078431372549;0.678431372549020,0.862745098039216,0.188235294117647;0.686274509803922,0.862745098039216,0.180392156862745;0.698039215686275,0.866666666666667,0.172549019607843;0.709803921568628,0.866666666666667,0.168627450980392;0.717647058823529,0.866666666666667,0.160784313725490;0.733333333333333,0.870588235294118,0.149019607843137;0.749019607843137,0.874509803921569,0.141176470588235;0.760784313725490,0.874509803921569,0.133333333333333;0.772549019607843,0.874509803921569,0.129411764705882;0.780392156862745,0.878431372549020,0.121568627450980;0.792156862745098,0.878431372549020,0.117647058823529;0.803921568627451,0.878431372549020,0.113725490196078;0.815686274509804,0.882352941176471,0.105882352941176;0.831372549019608,0.882352941176471,0.101960784313725;0.843137254901961,0.886274509803922,0.0980392156862745;0.854901960784314,0.886274509803922,0.0941176470588235;0.862745098039216,0.886274509803922,0.0941176470588235;0.874509803921569,0.890196078431373,0.0941176470588235;0.882352941176471,0.890196078431373,0.0941176470588235;0.905882352941177,0.894117647058824,0.0980392156862745;0.913725490196078,0.894117647058824,0.0980392156862745;0.925490196078431,0.894117647058824,0.101960784313725;0.933333333333333,0.898039215686275,0.105882352941176;0.945098039215686,0.898039215686275,0.109803921568627;0.952941176470588,0.898039215686275,0.117647058823529;0.964705882352941,0.901960784313726,0.121568627450980;0.980392156862745,0.901960784313726,0.133333333333333;0.992156862745098,0.905882352941177,0.141176470588235;0.992156862745098,0.905882352941177,0.141176470588235];

num = size(C,1);
vec = linspace(0,num+1,N+2);
map = interp1(1:num,C,vec(2:end-1),'linear','extrap'); %...��ֵ
map = max(0,min(1,map));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
% ����������            %%%
% ���ںţ������Ŀ����ճ� %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%