#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <assert.h>

/*
 * Required sizes of the temporary buffer (in bytes).
 *
 * This size is 28*2^logn bytes, except for degrees 2 and 4 (logn = 1
 * or 2) where it is slightly greater.
 */
#define FALCON_KEYGEN_TEMP_9    14336

/* ===================================================================== */
/*
 * Constants for NTT.
 *
 *   n = 2^logn  (2 <= n <= 1024)
 *   phi = X^n + 1
 *   q = 12289
 *   q0i = -1/q mod 2^16
 *   R = 2^16 mod q
 *   R2 = 2^32 mod q
 */

#define Q     12289
#define Q0I   12287
#define R      4091
#define R2    10952

// expected ff buff
uint16_t buff_tt[] = {65490,65524,140,13,276,126,65156,65490,65247,28,77,261,65531,327,65357,65267,101,65521,58,65415,49,302,65512,71,65290,207,272,65430,184,65497,65262,267,59,3,120,65360,65366,251,81,35,126,3,65502,18,385,65359,177,65189,65286,65475,539,65307,65352,53,124,65415,65438,138,84,62,187,65353,65420,51,65510,65462,82,65334,65313,35,55,61,65225,65498,65517,65378,129,29,65440,65195,20,79,65383,65410,40,65389,65457,65118,159,65450,299,64,65477,188,167,65474,68,305,119,65389,402,35,30,65486,65427,65485,264,223,7,164,65178,65372,298,65387,184,65434,65241,83,65504,200,65423,163,65462,289,65469,294,58,65159,298,56,65483,39,65352,65450,99,63,57,65480,65461,65437,65212,124,18,65531,173,65272,43,170,18,65395,65240,65152,150,65137,65434,65340,110,65250,65520,214,65459,50,133,65483,11,65509,65369,65223,268,58,65242,64,65418,159,298,65336,231,65530,65349,6,14,50,65474,65319,65496,29,65168,65312,21,115,201,12,65335,65490,92,131,65397,65486,65377,168,65520,8,65527,72,65425,65175,65509,25,91,65289,46,65509,227,147,65512,377,2,70,65146,8,128,15,200,65306,42,162,166,65505,187,65283,148,65393,0,65532,182,65526,65354,26,65457,91,65519,45,65477,87,20,65370,262,65404,65462,92,74,65369,65515,27,74,60,65390,186,65524,59,65428,65529,65495,65483,80,39,65476,87,148,54,119,65437,65478,65403,134,65458,253,65373,65398,65301,43,148,214,183,65535,140,65443,255,65346,65424,65246,65517,65519,313,110,65279,65505,65244,11,65532,65461,65291,65405,65427,65431,11,65355,65273,65194,65358,65188,36,191,65317,9,65266,286,52,213,214,141,65508,127,65490,65209,65362,81,65353,36,42,65377,182,65520,227,65438,65485,65525,302,65432,71,4,184,65480,89,65331,145,152,65487,90,118,214,99,61,77,253,65417,258,65419,86,188,65493,124,65219,65491,65306,65351,65464,308,283,79,65331,294,94,99,142,135,65313,65535,270,65385,54,175,65373,65381,65290,83,25,65236,65441,65359,65385,55,65526,89,65347,117,28,94,65405,65346,65456,77,42,65342,0,65423,65461,65486,361,68,67,65341,65480,418,65330,181,65474,61,65416,65391,65442,34,28,65355,321,128,392,76,226,231,61,65152,65520,36,83,65302,58,65306,325,65474,65376,65367,130,65488,65462,65460,99,65497,88,65369,65410,55,65485,65517,103,23,129,65347,65448,321,65368,2,118,65152,64922,90,65336,228,83,54,65526,3,65332,25,65405,196,228,65465,65510,173,85,65416,65423,479,65287,65410,56,65359,65205,85,75,131,65421,241,321,240,359,65499,298,85,66,138,65535,102,65525,65375,65390,65392,210,301,138,65470};


/*
 * Table for NTT, binary case:
 *   GMb[x] = R*(g^rev(x)) mod q
 * where g = 7 (it is a 2048-th primitive root of 1 modulo q)
 * and rev() is the bit-reversal function over 10 bits.
 */
static const uint16_t GMb[] = {
    4091,  7888, 11060, 11208,  6960,  4342,  6275,  9759,
    1591,  6399,  9477,  5266,   586,  5825,  7538,  9710,
    1134,  6407,  1711,   965,  7099,  7674,  3743,  6442,
    10414,  8100,  1885,  1688,  1364, 10329, 10164,  9180,
    12210,  6240,   997,   117,  4783,  4407,  1549,  7072,
    2829,  6458,  4431,  8877,  7144,  2564,  5664,  4042,
    12189,   432, 10751,  1237,  7610,  1534,  3983,  7863,
    2181,  6308,  8720,  6570,  4843,  1690,    14,  3872,
    5569,  9368, 12163,  2019,  7543,  2315,  4673,  7340,
    1553,  1156,  8401, 11389,  1020,  2967, 10772,  7045,
    3316, 11236,  5285, 11578, 10637, 10086,  9493,  6180,
    9277,  6130,  3323,   883, 10469,   489,  1502,  2851,
    11061,  9729,  2742, 12241,  4970, 10481, 10078,  1195,
    730,  1762,  3854,  2030,  5892, 10922,  9020,  5274,
    9179,  3604,  3782, 10206,  3180,  3467,  4668,  2446,
    7613,  9386,   834,  7703,  6836,  3403,  5351, 12276,
    3580,  1739, 10820,  9787, 10209,  4070, 12250,  8525,
    10401,  2749,  7338, 10574,  6040,   943,  9330,  1477,
    6865,  9668,  3585,  6633, 12145,  4063,  3684,  7680,
    8188,  6902,  3533,  9807,  6090,   727, 10099,  7003,
    6945,  1949,  9731, 10559,  6057,   378,  7871,  8763,
    8901,  9229,  8846,  4551,  9589, 11664,  7630,  8821,
    5680,  4956,  6251,  8388, 10156,  8723,  2341,  3159,
    1467,  5460,  8553,  7783,  2649,  2320,  9036,  6188,
    737,  3698,  4699,  5753,  9046,  3687,    16,   914,
    5186, 10531,  4552,  1964,  3509,  8436,  7516,  5381,
    10733,  3281,  7037,  1060,  2895,  7156,  8887,  5357,
    6409,  8197,  2962,  6375,  5064,  6634,  5625,   278,
    932, 10229,  8927,  7642,   351,  9298,   237,  5858,
    7692,  3146, 12126,  7586,  2053, 11285,  3802,  5204,
    4602,  1748, 11300,   340,  3711,  4614,   300, 10993,
    5070, 10049, 11616, 12247,  7421, 10707,  5746,  5654,
    3835,  5553,  1224,  8476,  9237,  3845,   250, 11209,
    4225,  6326,  9680, 12254,  4136,  2778,   692,  8808,
    6410,  6718, 10105, 10418,  3759,  7356, 11361,  8433,
    6437,  3652,  6342,  8978,  5391,  2272,  6476,  7416,
    8418, 10824, 11986,  5733,   876,  7030,  2167,  2436,
    3442,  9217,  8206,  4858,  5964,  2746,  7178,  1434,
    7389,  8879, 10661, 11457,  4220,  1432, 10832,  4328,
    8557,  1867,  9454,  2416,  3816,  9076,   686,  5393,
    2523,  4339,  6115,   619,   937,  2834,  7775,  3279,
    2363,  7488,  6112,  5056,   824, 10204, 11690,  1113,
    2727,  9848,   896,  2028,  5075,  2654, 10464,  7884,
    12169,  5434,  3070,  6400,  9132, 11672, 12153,  4520,
    1273,  9739, 11468,  9937, 10039,  9720,  2262,  9399,
    11192,   315,  4511,  1158,  6061,  6751, 11865,   357,
    7367,  4550,   983,  8534,  8352, 10126,  7530,  9253,
    4367,  5221,  3999,  8777,  3161,  6990,  4130, 11652,
    3374, 11477,  1753,   292,  8681,  2806, 10378, 12188,
    5800, 11811,  3181,  1988,  1024,  9340,  2477, 10928,
    4582,  6750,  3619,  5503,  5233,  2463,  8470,  7650,
    7964,  6395,  1071,  1272,  3474, 11045,  3291, 11344,
    8502,  9478,  9837,  1253,  1857,  6233,  4720, 11561,
    6034,  9817,  3339,  1797,  2879,  6242,  5200,  2114,
    7962,  9353, 11363,  5475,  6084,  9601,  4108,  7323,
    10438,  9471,  1271,   408,  6911,  3079,   360,  8276,
    11535,  9156,  9049, 11539,   850,  8617,   784,  7919,
    8334, 12170,  1846, 10213, 12184,  7827, 11903,  5600,
    9779,  1012,   721,  2784,  6676,  6552,  5348,  4424,
    6816,  8405,  9959,  5150,  2356,  5552,  5267,  1333,
    8801,  9661,  7308,  5788,  4910,   909, 11613,  4395,
    8238,  6686,  4302,  3044,  2285, 12249,  1963,  9216,
    4296, 11918,   695,  4371,  9793,  4884,  2411, 10230,
    2650,   841,  3890, 10231,  7248,  8505, 11196,  6688,
    4059,  6060,  3686,  4722, 11853,  5816,  7058,  6868,
    11137,  7926,  4894, 12284,  4102,  3908,  3610,  6525,
    7938,  7982, 11977,  6755,   537,  4562,  1623,  8227,
    11453,  7544,   906, 11816,  9548, 10858,  9703,  2815,
    11736,  6813,  6979,   819,  8903,  6271, 10843,   348,
    7514,  8339,  6439,   694,   852,  5659,  2781,  3716,
    11589,  3024,  1523,  8659,  4114, 10738,  3303,  5885,
    2978,  7289, 11884,  9123,  9323, 11830,    98,  2526,
    2116,  4131, 11407,  1844,  3645,  3916,  8133,  2224,
    10871,  8092,  9651,  5989,  7140,  8480,  1670,   159,
    10923,  4918,   128,  7312,   725,  9157,  5006,  6393,
    3494,  6043, 10972,  6181, 11838,  3423, 10514,  7668,
    3693,  6658,  6905, 11953, 10212, 11922,  9101,  8365,
    5110,    45,  2400,  1921,  4377,  2720,  1695,    51,
    2808,   650,  1896,  9997,  9971, 11980,  8098,  4833,
    4135,  4257,  5838,  4765, 10985, 11532,   590, 12198,
    482, 12173,  2006,  7064, 10018,  3912, 12016, 10519,
    11362,  6954,  2210,   284,  5413,  6601,  3865, 10339,
    11188,  6231,   517,  9564, 11281,  3863,  1210,  4604,
    8160, 11447,   153,  7204,  5763,  5089,  9248, 12154,
    11748,  1354,  6672,   179,  5532,  2646,  5941, 12185,
    862,  3158,   477,  7279,  5678,  7914,  4254,   302,
    2893, 10114,  6890,  9560,  9647, 11905,  4098,  9824,
    10269,  1353, 10715,  5325,  6254,  3951,  1807,  6449,
    5159,  1308,  8315,  3404,  1877,  1231,   112,  6398,
    11724, 12272,  7286,  1459, 12274,  9896,  3456,   800,
    1397, 10678,   103,  7420,  7976,   936,   764,   632,
    7996,  8223,  8445,  7758, 10870,  9571,  2508,  1946,
    6524, 10158,  1044,  4338,  2457,  3641,  1659,  4139,
    4688,  9733, 11148,  3946,  2082,  5261,  2036, 11850,
    7636, 12236,  5366,  2380,  1399,  7720,  2100,  3217,
    10912,  8898,  7578, 11995,  2791,  1215,  3355,  2711,
    2267,  2004,  8568, 10176,  3214,  2337,  1750,  4729,
    4997,  7415,  6315, 12044,  4374,  7157,  4844,   211,
    8003, 10159,  9290, 11481,  1735,  2336,  5793,  9875,
    8192,   986,  7527,  1401,   870,  3615,  8465,  2756,
    9770,  2034, 10168,  3264,  6132,    54,  2880,  4763,
    11805,  3074,  8286,  9428,  4881,  6933,  1090, 10038,
    2567,   708,   893,  6465,  4962, 10024,  2090,  5718,
    10743,   780,  4733,  4623,  2134,  2087,  4802,   884,
    5372,  5795,  5938,  4333,  6559,  7549,  5269, 10664,
    4252,  3260,  5917, 10814,  5768,  9983,  8096,  7791,
    6800,  7491,  6272,  1907, 10947,  6289, 11803,  6032,
    11449,  1171,  9201,  7933,  2479,  7970, 11337,  7062,
    8911,  6728,  6542,  8114,  8828,  6595,  3545,  4348,
    4610,  2205,  6999,  8106,  5560, 10390,  9321,  2499,
    2413,  7272,  6881, 10582,  9308,  9437,  3554,  3326,
    5991, 11969,  3415, 12283,  9838, 12063,  4332,  7830,
    11329,  6605, 12271,  2044, 11611,  7353, 11201, 11582,
    3733,  8943,  9978,  1627,  7168,  3935,  5050,  2762,
    7496, 10383,   755,  1654, 12053,  4952, 10134,  4394,
    6592,  7898,  7497,  8904, 12029,  3581, 10748,  5674,
    10358,  4901,  7414,  8771,   710,  6764,  8462,  7193,
    5371,  7274, 11084,   290,  7864,  6827, 11822,  2509,
    6578,  4026,  5807,  1458,  5721,  5762,  4178,  2105,
    11621,  4852,  8897,  2856, 11510,  9264,  2520,  8776,
    7011,  2647,  1898,  7039,  5950, 11163,  5488,  6277,
    9182, 11456,   633, 10046, 11554,  5633,  9587,  2333,
    7008,  7084,  5047,  7199,  9865,  8997,   569,  6390,
    10845,  9679,  8268, 11472,  4203,  1997,     2,  9331,
    162,  6182,  2000,  3649,  9792,  6363,  7557,  6187,
    8510,  9935,  5536,  9019,  3706, 12009,  1452,  3067,
    5494,  9692,  4865,  6019,  7106,  9610,  4588, 10165,
    6261,  5887,  2652, 10172,  1580, 10379,  4638,  9949
};

/*
 * Table for inverse NTT, binary case:
 *   iGMb[x] = R*((1/g)^rev(x)) mod q
 * Since g = 7, 1/g = 8778 mod 12289.
 */
static const uint16_t iGMb[] = {
    4091,  4401,  1081,  1229,  2530,  6014,  7947,  5329,
    2579,  4751,  6464, 11703,  7023,  2812,  5890, 10698,
    3109,  2125,  1960, 10925, 10601, 10404,  4189,  1875,
    5847,  8546,  4615,  5190, 11324, 10578,  5882, 11155,
    8417, 12275, 10599,  7446,  5719,  3569,  5981, 10108,
    4426,  8306, 10755,  4679, 11052,  1538, 11857,   100,
    8247,  6625,  9725,  5145,  3412,  7858,  5831,  9460,
    5217, 10740,  7882,  7506, 12172, 11292,  6049,    79,
    13,  6938,  8886,  5453,  4586, 11455,  2903,  4676,
    9843,  7621,  8822,  9109,  2083,  8507,  8685,  3110,
    7015,  3269,  1367,  6397, 10259,  8435, 10527, 11559,
    11094,  2211,  1808,  7319,    48,  9547,  2560,  1228,
    9438, 10787, 11800,  1820, 11406,  8966,  6159,  3012,
    6109,  2796,  2203,  1652,   711,  7004,  1053,  8973,
    5244,  1517,  9322, 11269,   900,  3888, 11133, 10736,
    4949,  7616,  9974,  4746, 10270,   126,  2921,  6720,
    6635,  6543,  1582,  4868,    42,   673,  2240,  7219,
    1296, 11989,  7675,  8578, 11949,   989, 10541,  7687,
    7085,  8487,  1004, 10236,  4703,   163,  9143,  4597,
    6431, 12052,  2991, 11938,  4647,  3362,  2060, 11357,
    12011,  6664,  5655,  7225,  5914,  9327,  4092,  5880,
    6932,  3402,  5133,  9394, 11229,  5252,  9008,  1556,
    6908,  4773,  3853,  8780, 10325,  7737,  1758,  7103,
    11375, 12273,  8602,  3243,  6536,  7590,  8591, 11552,
    6101,  3253,  9969,  9640,  4506,  3736,  6829, 10822,
    9130,  9948,  3566,  2133,  3901,  6038,  7333,  6609,
    3468,  4659,   625,  2700,  7738,  3443,  3060,  3388,
    3526,  4418, 11911,  6232,  1730,  2558, 10340,  5344,
    5286,  2190, 11562,  6199,  2482,  8756,  5387,  4101,
    4609,  8605,  8226,   144,  5656,  8704,  2621,  5424,
    10812,  2959, 11346,  6249,  1715,  4951,  9540,  1888,
    3764,    39,  8219,  2080,  2502,  1469, 10550,  8709,
    5601,  1093,  3784,  5041,  2058,  8399, 11448,  9639,
    2059,  9878,  7405,  2496,  7918, 11594,   371,  7993,
    3073, 10326,    40, 10004,  9245,  7987,  5603,  4051,
    7894,   676, 11380,  7379,  6501,  4981,  2628,  3488,
    10956,  7022,  6737,  9933,  7139,  2330,  3884,  5473,
    7865,  6941,  5737,  5613,  9505, 11568, 11277,  2510,
    6689,   386,  4462,   105,  2076, 10443,   119,  3955,
    4370, 11505,  3672, 11439,   750,  3240,  3133,   754,
    4013, 11929,  9210,  5378, 11881, 11018,  2818,  1851,
    4966,  8181,  2688,  6205,  6814,   926,  2936,  4327,
    10175,  7089,  6047,  9410, 10492,  8950,  2472,  6255,
    728,  7569,  6056, 10432, 11036,  2452,  2811,  3787,
    945,  8998,  1244,  8815, 11017, 11218,  5894,  4325,
    4639,  3819,  9826,  7056,  6786,  8670,  5539,  7707,
    1361,  9812,  2949, 11265, 10301,  9108,   478,  6489,
    101,  1911,  9483,  3608, 11997, 10536,   812,  8915,
    637,  8159,  5299,  9128,  3512,  8290,  7068,  7922,
    3036,  4759,  2163,  3937,  3755, 11306,  7739,  4922,
    11932,   424,  5538,  6228, 11131,  7778, 11974,  1097,
    2890, 10027,  2569,  2250,  2352,   821,  2550, 11016,
    7769,   136,   617,  3157,  5889,  9219,  6855,   120,
    4405,  1825,  9635,  7214, 10261, 11393,  2441,  9562,
    11176,   599,  2085, 11465,  7233,  6177,  4801,  9926,
    9010,  4514,  9455, 11352, 11670,  6174,  7950,  9766,
    6896, 11603,  3213,  8473,  9873,  2835, 10422,  3732,
    7961,  1457, 10857,  8069,   832,  1628,  3410,  4900,
    10855,  5111,  9543,  6325,  7431,  4083,  3072,  8847,
    9853, 10122,  5259, 11413,  6556,   303,  1465,  3871,
    4873,  5813, 10017,  6898,  3311,  5947,  8637,  5852,
    3856,   928,  4933,  8530,  1871,  2184,  5571,  5879,
    3481, 11597,  9511,  8153,    35,  2609,  5963,  8064,
    1080, 12039,  8444,  3052,  3813, 11065,  6736,  8454,
    2340,  7651,  1910, 10709,  2117,  9637,  6402,  6028,
    2124,  7701,  2679,  5183,  6270,  7424,  2597,  6795,
    9222, 10837,   280,  8583,  3270,  6753,  2354,  3779,
    6102,  4732,  5926,  2497,  8640, 10289,  6107, 12127,
    2958, 12287, 10292,  8086,   817,  4021,  2610,  1444,
    5899, 11720,  3292,  2424,  5090,  7242,  5205,  5281,
    9956,  2702,  6656,   735,  2243, 11656,   833,  3107,
    6012,  6801,  1126,  6339,  5250, 10391,  9642,  5278,
    3513,  9769,  3025,   779,  9433,  3392,  7437,   668,
    10184,  8111,  6527,  6568, 10831,  6482,  8263,  5711,
    9780,   467,  5462,  4425, 11999,  1205,  5015,  6918,
    5096,  3827,  5525, 11579,  3518,  4875,  7388,  1931,
    6615,  1541,  8708,   260,  3385,  4792,  4391,  5697,
    7895,  2155,  7337,   236, 10635, 11534,  1906,  4793,
    9527,  7239,  8354,  5121, 10662,  2311,  3346,  8556,
    707,  1088,  4936,   678, 10245,    18,  5684,   960,
    4459,  7957,   226,  2451,     6,  8874,   320,  6298,
    8963,  8735,  2852,  2981,  1707,  5408,  5017,  9876,
    9790,  2968,  1899,  6729,  4183,  5290, 10084,  7679,
    7941,  8744,  5694,  3461,  4175,  5747,  5561,  3378,
    5227,   952,  4319,  9810,  4356,  3088, 11118,   840,
    6257,   486,  6000,  1342, 10382,  6017,  4798,  5489,
    4498,  4193,  2306,  6521,  1475,  6372,  9029,  8037,
    1625,  7020,  4740,  5730,  7956,  6351,  6494,  6917,
    11405,  7487, 10202, 10155,  7666,  7556, 11509,  1546,
    6571, 10199,  2265,  7327,  5824, 11396, 11581,  9722,
    2251, 11199,  5356,  7408,  2861,  4003,  9215,   484,
    7526,  9409, 12235,  6157,  9025,  2121, 10255,  2519,
    9533,  3824,  8674, 11419, 10888,  4762, 11303,  4097,
    2414,  6496,  9953, 10554,   808,  2999,  2130,  4286,
    12078,  7445,  5132,  7915,   245,  5974,  4874,  7292,
    7560, 10539,  9952,  9075,  2113,  3721, 10285, 10022,
    9578,  8934, 11074,  9498,   294,  4711,  3391,  1377,
    9072, 10189,  4569, 10890,  9909,  6923,    53,  4653,
    439, 10253,  7028, 10207,  8343,  1141,  2556,  7601,
    8150, 10630,  8648,  9832,  7951, 11245,  2131,  5765,
    10343,  9781,  2718,  1419,  4531,  3844,  4066,  4293,
    11657, 11525, 11353,  4313,  4869, 12186,  1611, 10892,
    11489,  8833,  2393,    15, 10830,  5003,    17,   565,
    5891, 12177, 11058, 10412,  8885,  3974, 10981,  7130,
    5840, 10482,  8338,  6035,  6964,  1574, 10936,  2020,
    2465,  8191,   384,  2642,  2729,  5399,  2175,  9396,
    11987,  8035,  4375,  6611,  5010, 11812,  9131, 11427,
    104,  6348,  9643,  6757, 12110,  5617, 10935,   541,
    135,  3041,  7200,  6526,  5085, 12136,   842,  4129,
    7685, 11079,  8426,  1008,  2725, 11772,  6058,  1101,
    1950,  8424,  5688,  6876, 12005, 10079,  5335,   927,
    1770,   273,  8377,  2271,  5225, 10283,   116, 11807,
    91, 11699,   757,  1304,  7524,  6451,  8032,  8154,
    7456,  4191,   309,  2318,  2292, 10393, 11639,  9481,
    12238, 10594,  9569,  7912, 10368,  9889, 12244,  7179,
    3924,  3188,   367,  2077,   336,  5384,  5631,  8596,
    4621,  1775,  8866,   451,  6108,  1317,  6246,  8795,
    5896,  7283,  3132, 11564,  4977, 12161,  7371,  1366,
    12130, 10619,  3809,  5149,  6300,  2638,  4197,  1418,
    10065,  4156,  8373,  8644, 10445,   882,  8158, 10173,
    9763, 12191,   459,  2966,  3166,   405,  5000,  9311,
    6404,  8986,  1551,  8175,  3630, 10766,  9265,   700,
    8573,  9508,  6630, 11437, 11595,  5850,  3950,  4775,
    11941,  1446,  6018,  3386, 11470,  5310,  5476,   553,
    9474,  2586,  1431,  2741,   473, 11383,  4745,   836,
    4062, 10666,  7727, 11752,  5534,   312,  4307,  4351,
    5764,  8679,  8381,  8187,     5,  7395,  4363,  1152,
    5421,  5231,  6473,   436,  7567,  8603,  6229,  8230
};
/* ===================================================================== */


static void print_uint16_array(FILE *f, uint16_t *a, uint16_t n) {
  uint32_t i, k;
  fprintf(f, "[");

  k = 0;
  for (i=0; i<n; i++) {
    if (k == 0) fprintf(f, " ");
    fprintf(f, "%d", a[i]);
    k ++;
    if (k == 16) {
      fprintf(f, ",");
      k = 0;
    } else {
      fprintf(f, ", ");
    }
  }
//   if (k > 0) {
//     fprintf(f, "\n");
//   }
  fprintf(f, "]\n");
}

/*
 * Addition modulo q. Operands must be in the 0..q-1 range.
 */
static inline uint32_t
mq_add(uint32_t x, uint32_t y) {
    /*
     * We compute x + y - q. If the result is negative, then the
     * high bit will be set, and 'd >> 31' will be equal to 1;
     * thus '-(d >> 31)' will be an all-one pattern. Otherwise,
     * it will be an all-zero pattern. In other words, this
     * implements a conditional addition of q.
     */
    uint32_t d;

    d = x + y - Q;
    d += Q & -(d >> 31);
    return d;
}


/*
 * Subtraction modulo q. Operands must be in the 0..q-1 range.
 */
static inline uint32_t
mq_sub(uint32_t x, uint32_t y) {
    /*
     * As in mq_add(), we use a conditional addition to ensure the
     * result is in the 0..q-1 range.
     */
    uint32_t d;

    d = x - y;
    d += Q & -(d >> 31);
    return d;
}


/*
 * Division by 2 modulo q. Operand must be in the 0..q-1 range.
 */
static inline uint32_t
mq_rshift1(uint32_t x) {
    x += Q & -(x & 1);
    return (x >> 1);
}


/*
 * Subtract polynomial g from polynomial f.
 */
static void
mq_poly_sub(uint16_t *f, const uint16_t *g, unsigned logn) {
    size_t u, n;

    n = (size_t)1 << logn;
    for (u = 0; u < n; u ++) {
        f[u] = (uint16_t)mq_sub(f[u], g[u]);
    }
}


/*
 * Montgomery multiplication modulo q. If we set R = 2^16 mod q, then
 * this function computes: x * y / R mod q
 * Operands must be in the 0..q-1 range.
 */
static inline uint32_t
mq_montymul(uint32_t x, uint32_t y) {
    uint32_t z, w;

    /*
     * We compute x*y + k*q with a value of k chosen so that the 16
     * low bits of the result are 0. We can then shift the value.
     * After the shift, result may still be larger than q, but it
     * will be lower than 2*q, so a conditional subtraction works.
     */

    z = x * y;
    w = ((z * Q0I) & 0xFFFF) * Q;

    /*
     * When adding z and w, the result will have its low 16 bits
     * equal to 0. Since x, y and z are lower than q, the sum will
     * be no more than (2^15 - 1) * q + (q - 1)^2, which will
     * fit on 29 bits.
     */
    z = (z + w) >> 16;

    /*
     * After the shift, analysis shows that the value will be less
     * than 2q. We do a subtraction then conditional subtraction to
     * ensure the result is in the expected range.
     */
    z -= Q;
    z += Q & -(z >> 31);
    return z;
}


/*
 * Multiply two polynomials together (NTT representation, and using
 * a Montgomery multiplication). Result f*g is written over f.
 */
static void
mq_poly_montymul_ntt(uint16_t *f, const uint16_t *g, unsigned logn) {
    size_t u, n;

    n = (size_t)1 << logn;
    for (u = 0; u < n; u ++) {
        f[u] = (uint16_t)mq_montymul(f[u], g[u]);
    }
}


/*
 * Compute NTT on a ring element.
 */
static void
mq_NTT(uint16_t *a, unsigned logn) {
    size_t n, t, m;

    n = (size_t)1 << logn;
    t = n;
    for (m = 1; m < n; m <<= 1) {
        size_t ht, i, j1;

        ht = t >> 1;
        for (i = 0, j1 = 0; i < m; i ++, j1 += t) {
            size_t j, j2;
            uint32_t s;

            s = GMb[m + i];
            j2 = j1 + ht;
            for (j = j1; j < j2; j ++) {
                uint32_t u, v;

                u = a[j];
                v = mq_montymul(a[j + ht], s);
                a[j] = (uint16_t)mq_add(u, v);
                a[j + ht] = (uint16_t)mq_sub(u, v);
            }
        }
        t = ht;
    }
}

static void
mq_poly_tomonty(uint16_t *f, unsigned logn) {
    size_t u, n;

    n = (size_t)1 << logn;
    for (u = 0; u < n; u ++) {
        f[u] = (uint16_t)mq_montymul(f[u], R2);
    }
}

/*
 * Compute the inverse NTT on a ring element, binary case.
 */
static void
mq_iNTT(uint16_t *a, unsigned logn) {
    size_t n, t, m;
    uint32_t ni;

    n = (size_t)1 << logn;
    t = 1;
    m = n;
    while (m > 1) {
        size_t hm, dt, i, j1;

        hm = m >> 1;
        dt = t << 1;
        for (i = 0, j1 = 0; i < hm; i ++, j1 += dt) {
            size_t j, j2;
            uint32_t s;

            j2 = j1 + t;
            s = iGMb[hm + i];
            for (j = j1; j < j2; j ++) {
                uint32_t u, v, w;

                u = a[j];
                v = a[j + t];
                a[j] = (uint16_t)mq_add(u, v);
                w = mq_sub(u, v);
                a[j + t] = (uint16_t)
                           mq_montymul(w, s);
            }
        }
        t = dt;
        m = hm;
    }

    /*
     * To complete the inverse NTT, we must now divide all values by
     * n (the vector size). We thus need the inverse of n, i.e. we
     * need to divide 1 by 2 logn times. But we also want it in
     * Montgomery representation, i.e. we also want to multiply it
     * by R = 2^16. In the common case, this should be a simple right
     * shift. The loop below is generic and works also in corner cases;
     * its computation time is negligible.
     */
    ni = R;
    for (m = n; m > 1; m >>= 1) {
        ni = mq_rshift1(ni);
    }
    for (m = 0; m < n; m ++) {
        a[m] = (uint16_t)mq_montymul(a[m], ni);
    }
}


/*
 * Tell whether a given vector (2N coordinates, in two halves) is
 * acceptable as a signature. This compares the appropriate norm of the
 * vector with the acceptance bound. Returned value is 1 on success
 * (vector is short enough to be acceptable), 0 otherwise.
 */
static int
PQCLEAN_FALCON512_CLEAN_is_short(
    const int16_t *s1, const int16_t *s2, unsigned logn) {
    /*
     * We use the l2-norm. Code below uses only 32-bit operations to
     * compute the square of the norm with saturation to 2^32-1 if
     * the value exceeds 2^31-1.
     */
    size_t n, u;
    uint32_t s, ng;

    n = (size_t)1 << logn;
    s = 0;
    ng = 0;
    for (u = 0; u < n; u ++) {
        int32_t z;

        z = s1[u];
        s += (uint32_t)(z * z);
        ng |= s;
        z = s2[u];
        s += (uint32_t)(z * z);
        ng |= s;
    }
    s |= -(ng >> 31);

    /*
     * Acceptance bound on the l2-norm is:
     *   1.2*1.55*sqrt(q)*sqrt(2*N)
     * Value 7085 is floor((1.2^2)*(1.55^2)*2*1024).
     */
    return s < (((uint32_t)7085 * (uint32_t)12289) >> (10 - logn));
}


// /*
 // * Convert a public key to NTT + Montgomery format. Conversion is done
 // * in place.
 // */
// static void
// PQCLEAN_FALCON512_CLEAN_to_ntt_monty(uint16_t *h, unsigned logn) {
// mq_NTT(h, logn);
// mq_poly_tomonty(h, logn);
// }

/* Internal signature verification code:
 *   c0[]      contains the hashed nonce+message
 *   s2[]      is the decoded signature
 *   h[]       contains the public key, in NTT + Montgomery format
 *   logn      is the degree log
 *   tmp[]     temporary, must have at least 2*2^logn bytes
 * Returned value is 1 on success, 0 on error.
 *
 * tmp[] must have 16-bit alignment.
 */
static int
PQCLEAN_FALCON512_CLEAN_verify_raw(const uint16_t *c0, const int16_t *s2,
                                   uint16_t *h, unsigned logn, uint8_t *tmp) {
    size_t u, n;
    uint16_t *tt;

    n = (size_t)1 << logn;
    tt = (uint16_t *)tmp;
    
    /*
     * Reduce s2 elements modulo q ([0..q-1] range).
     */
    for (u = 0; u < n; u ++) {
        uint32_t w;

        w = (uint32_t)s2[u];
        w += Q & -(w >> 31);
        tt[u] = (uint16_t)w;
    }

    /*
     * Compute -s1 = s2*h - c0 mod phi mod q (in tt[]).
     */
    print_uint16_array(stdout, h, 512);
    print_uint16_array(stdout, tt, 512);

    mq_NTT(h, logn);
    mq_poly_tomonty(h, logn);
    mq_NTT(tt, logn);
    mq_poly_montymul_ntt(tt, h, logn);
    mq_iNTT(tt, logn);

    // this should end up doing poly multiplication 
    print_uint16_array(stdout, tt, 512);

    mq_poly_sub(tt, c0, logn);

    /*
     * Normalize -s1 elements into the [-q/2..q/2] range.
     */
    for (u = 0; u < n; u ++) {
        int32_t w;

        w = (int32_t)tt[u];
        w -= (int32_t)(Q & -(((Q >> 1) - (uint32_t)w) >> 31));
        ((int16_t *)tt)[u] = (int16_t)w;
    }

    for (u = 0; u < 512; u ++) {
        assert(tt[u] == buff_tt[u]);
    }


    /*
     * Signature is valid if and only if the aggregate (-s1,s2) vector
     * is short enough.
     */
    return PQCLEAN_FALCON512_CLEAN_is_short((int16_t *)tt, s2, logn);
}


int main(void) {
    uint8_t tmp[FALCON_KEYGEN_TEMP_9];

    uint16_t buff_c0[] = {6673,10315,10940,3299,4987,5662,11800,9550,2694,7285,10708,9271,5302,10252,6550,4379,4864,610,7943,7824,5114,1447,6056,10284,11092,134,9036,3609,1300,12158,3845,9665,9733,1286,2694,3234,11398,5564,3406,1286,1931,8562,9165,1804,5996,11429,10552,6082,5037,7371,1689,12099,114,4137,5378,10635,6542,949,7802,9975,7195,4071,5425,9455,7531,139,11058,3459,6055,3991,11095,3331,9444,2786,2748,12130,10999,3562,7589,11383,11600,7646,8820,6571,13,1737,12199,5000,11779,4521,9776,3389,10782,8206,151,4370,7577,5380,501,6168,8233,9495,4724,3681,10087,8825,639,331,2216,5575,578,12232,6630,2559,3943,6350,1147,1979,7196,12003,1990,1946,11435,4858,1823,2570,5424,4417,10835,230,7174,6230,3965,7457,7365,6346,11573,7818,5093,10342,3646,11570,10541,1032,1714,11984,1599,2658,7471,3183,4841,1487,6818,6149,59,4224,11243,8476,10957,4761,6515,4821,4695,8327,3346,816,8069,10736,9283,7802,9985,12079,2597,9995,4482,6078,5882,3901,10058,10522,2821,2967,2082,9161,2133,2091,12077,3077,2426,7337,8708,6529,4377,5990,11895,5074,11521,8196,3455,7557,8214,6193,225,6541,5001,8846,4592,7685,4887,1958,4335,11441,5325,5959,802,7885,4183,2282,8597,4655,6144,2393,3354,1892,4025,5517,8980,5598,3140,3632,769,351,205,11781,2038,4797,271,9645,9006,681,8735,1765,5566,4225,10729,8154,12210,11994,8839,3632,7146,3860,1842,6456,2263,3770,2108,7291,2141,8070,8768,5603,12278,8039,3818,7992,6229,10915,2514,9612,9591,3061,1820,9580,12023,137,4519,5137,9208,4363,7112,2069,8425,11266,10784,12254,7314,14,6773,10897,6175,3446,8319,131,5493,9103,3454,10593,1849,10906,6904,3968,5873,913,1569,6431,7643,1451,3955,5784,5521,7948,5371,549,4727,6231,10299,980,11328,4806,619,182,1241,2903,1555,9013,9358,3462,4332,839,3895,469,5210,7597,7962,9497,10476,7109,2908,6482,5191,2153,6025,7581,7426,4571,4299,3812,3498,7244,4274,2022,8859,1670,12263,7258,7447,6788,2368,3473,10732,11379,11349,4244,144,11120,3583,11084,10320,7677,3648,11926,1727,5563,4196,9718,6620,959,1427,10017,4524,5386,1855,8744,3044,8480,9773,10804,7236,10273,2600,9864,2883,12040,5423,11087,8480,3826,8325,2103,2023,5979,9077,5463,7261,7750,10123,6595,7930,3869,12113,11,7509,4414,9764,5654,2063,592,4909,7381,11924,5296,678,11707,9237,5175,11937,2000,1783,6735,7838,6899,6358,8466,10072,4448,431,11900,7165,11098,1484,6558,9408,1946,12235,2949,9597,5259,11990,4477,10820,954,2897,3795,12120,7465,4025,10707,2944,8986,9069,8695,11418,7097,3889,995,2041,8724,12215,942,2300,11281,10910,8256,8645,5329,5550,4095,8297,6398,1056,5408,4645,1146,6612,12199,2656,6493,4550,5902,6539,2743,7884,11490,3665,6152,5200,556,6490,571,794,9852,1811,5973,10142,3747,9328,3682,7614,4133,7798,3711};
    uint16_t buff_h[] = {308,5674,2938,937,513,10228,10316,6784,3124,10820,1141,4726,12037,11917,11696,2060,2858,10057,9324,2319,2888,5145,371,5961,9647,11284,4746,7851,8011,7430,7519,10929,2904,596,10283,10505,3605,11360,3900,4296,6396,5344,2473,11273,4427,10534,6248,5018,9514,11213,11410,10591,10688,4771,7718,11389,6483,7925,1610,8049,98,3983,7269,1263,1294,11419,402,3386,9792,8966,2191,1697,135,4170,11940,1255,7542,5118,8403,3113,8999,3774,3450,11821,7942,1541,11389,7729,10750,12163,4382,9027,8877,12236,11169,2378,7923,3740,7507,7693,6020,5349,8301,1283,11198,1685,4745,1141,368,4269,7860,12200,6433,1943,749,6428,6449,5457,7078,2430,6211,6731,1848,4943,10122,6667,2740,3668,9643,4512,6103,1199,8768,670,5246,6441,7479,4692,6742,11512,2859,11844,7075,7202,11946,5616,3872,11261,8679,11798,5728,8072,2773,5138,2052,6537,5566,4719,8474,8630,11562,7286,10423,5567,4631,1875,9842,11844,6385,8223,11709,3788,9957,783,4445,3084,6571,11340,10118,5374,7923,10385,9753,3522,5145,5827,535,12169,2679,6849,9451,8172,6463,7946,7227,2909,2713,9886,2775,9894,7635,9709,4547,4599,129,3773,5869,11848,8187,6147,8436,7398,5721,3849,9164,3697,4975,3479,7509,1618,5712,6599,3697,189,3953,9253,7503,7633,6416,8057,1428,221,9371,8131,1888,11280,8952,9997,11818,8758,8760,10835,267,11251,1360,11675,417,6464,3134,4128,8966,10097,5584,3967,10668,5433,7370,3552,4568,5922,12184,9928,9256,10187,7470,7895,6469,10796,8526,8869,8525,4655,8865,9896,9514,2426,12121,6146,10130,6862,6293,6967,9197,8375,9187,7781,5827,147,8572,11116,10371,8106,9270,3685,8636,533,8596,6148,12270,9751,3693,3460,9934,9899,2857,9816,2526,8895,11004,2559,7380,7372,1741,4345,10756,3202,148,10513,11460,649,3081,11077,774,3907,4145,6951,11026,6090,11338,11340,6319,3316,5232,10784,6202,629,4776,959,11773,6858,1944,6529,7290,10946,2938,7897,5582,11495,8738,9329,5117,4659,8927,11602,2969,7196,1799,4967,6529,6382,9194,5136,4863,2179,4237,6763,2864,7202,11662,3419,5327,10109,4404,662,11953,1663,9576,11623,11832,6337,5235,4237,12262,5452,8358,1908,3727,3960,2164,2351,3679,2455,5285,10959,11242,7442,3629,5474,4908,2905,6379,3080,1658,10599,10743,11096,12063,10721,9675,4995,11614,1645,6427,3228,5132,10619,6031,1508,5885,5535,66,1672,11467,4029,5678,9628,7434,9673,8710,8657,3637,6590,1454,11765,846,2792,7187,5235,3005,6414,11054,7313,5880,528,369,9388,11768,1215,2590,7761,484,2214,11229,1028,5115,8868,12266,10812,7880,5108,8717,9361,3242,7185,1069,2801,10923,8266,10663,8701,187,3233,2343,8827,8903,10803,2006,10098,1306,11329,5315,11430,7683,6331,11304,1334,4542,4513,9917,1260,9488,2105,950,2622,287,11985,1009,5567,8205,2044,5968,8808,6339,4580,10256,2134,1182,3976,1977,50,2688,1143};
    int16_t buff_s2[] = {-211,39,56,180,-287,-64,-142,-178,-197,-53,262,196,86,0,-100,124,-116,-38,152,155,34,226,114,105,69,329,26,28,-92,35,-131,17,124,-298,-159,-140,168,-157,-181,2,174,58,-142,32,-142,-280,-95,-70,215,-277,-157,-43,17,2,448,-30,557,-93,12,285,-163,61,-114,125,188,-139,160,203,-423,67,-187,0,273,82,-6,-212,186,167,41,96,238,139,9,-97,-246,-89,29,68,172,-100,175,-149,-137,-66,121,-30,2,-62,-140,277,-18,280,70,-153,385,-356,484,29,74,145,138,53,-141,184,136,57,126,-140,132,-12,-224,222,-199,-140,44,-182,58,-194,24,-263,-5,-148,47,138,324,-143,182,-124,-32,-57,79,161,84,-130,116,228,-14,-114,-25,89,-120,129,264,11,67,-110,-162,-229,-244,-27,7,-209,139,-157,65,-102,-55,123,-295,-258,-104,-145,77,-7,-79,-30,-77,226,-121,2,-139,-29,-161,198,-139,3,-194,-49,179,113,-81,-2,-41,-118,-61,-208,-67,28,150,-169,-145,304,33,22,159,255,-84,-182,-376,264,57,206,65,44,169,-26,51,-306,-200,-183,-436,214,226,-56,-71,43,-207,136,67,319,-48,-130,132,117,110,-326,-13,-169,-48,-176,-314,-142,-217,-100,-13,-38,-26,-294,-47,227,89,175,-173,42,117,-93,-47,-29,19,100,-61,-185,-202,187,66,40,72,50,-12,-16,-161,238,8,-150,-17,-168,-36,80,47,-89,98,-179,117,317,-261,376,18,-40,10,44,-115,121,174,-361,214,-111,129,-63,-214,471,23,-128,199,-95,-184,-198,74,-127,160,-336,76,-159,-19,-232,-9,16,128,175,49,-91,68,-180,-42,-51,-53,-43,84,155,53,190,-96,-113,-66,-42,-230,134,249,-95,-280,-25,-123,5,-176,310,-195,149,53,197,38,-150,300,-13,62,-73,160,-185,52,-168,-33,74,310,-83,28,-338,-148,-41,115,-64,124,-6,-135,-37,-23,-92,132,-82,-122,123,236,35,57,198,159,133,-127,139,166,-95,-142,-102,-39,32,-171,119,14,177,10,128,219,5,1,27,-40,191,-66,-118,-116,41,-218,-46,276,-27,-145,86,-162,86,-156,120,58,103,173,-65,-175,45,-7,-146,158,53,15,-212,-111,223,503,-21,214,85,179,82,61,-84,77,98,106,278,-23,169,-119,-443,-3,220,98,141,250,7,37,-36,99,58,-88,46,130,-305,161,269,-25,47,-260,94,28,146,-252,-123,-292,-65,-68,-244,-238,87,-229,-125,216,-38,-81,288,-225,-135,300,-191,-84,214,-133,62,-78,438,114,-74,-242,-182,142,-72,-244,4,-186,-68,-192,-191,335,52,85,97,91,16};

    int32_t verify = PQCLEAN_FALCON512_CLEAN_verify_raw(buff_c0, buff_s2, buff_h, 9, tmp);
    return 0;
}
