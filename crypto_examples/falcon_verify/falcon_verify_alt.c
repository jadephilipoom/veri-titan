#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <assert.h>

#define PQCLEAN_FALCON512_CLEAN_CRYPTO_SECRETKEYBYTES   1281
#define PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES   897
#define PQCLEAN_FALCON512_CLEAN_CRYPTO_BYTES            690

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
#define BITREV512_NPAIRS 240

uint16_t buff_tt[] = {65490,65524,140,13,276,126,65156,65490,65247,28,77,261,65531,327,65357,65267,101,65521,58,65415,49,302,65512,71,65290,207,272,65430,184,65497,65262,267,59,3,120,65360,65366,251,81,35,126,3,65502,18,385,65359,177,65189,65286,65475,539,65307,65352,53,124,65415,65438,138,84,62,187,65353,65420,51,65510,65462,82,65334,65313,35,55,61,65225,65498,65517,65378,129,29,65440,65195,20,79,65383,65410,40,65389,65457,65118,159,65450,299,64,65477,188,167,65474,68,305,119,65389,402,35,30,65486,65427,65485,264,223,7,164,65178,65372,298,65387,184,65434,65241,83,65504,200,65423,163,65462,289,65469,294,58,65159,298,56,65483,39,65352,65450,99,63,57,65480,65461,65437,65212,124,18,65531,173,65272,43,170,18,65395,65240,65152,150,65137,65434,65340,110,65250,65520,214,65459,50,133,65483,11,65509,65369,65223,268,58,65242,64,65418,159,298,65336,231,65530,65349,6,14,50,65474,65319,65496,29,65168,65312,21,115,201,12,65335,65490,92,131,65397,65486,65377,168,65520,8,65527,72,65425,65175,65509,25,91,65289,46,65509,227,147,65512,377,2,70,65146,8,128,15,200,65306,42,162,166,65505,187,65283,148,65393,0,65532,182,65526,65354,26,65457,91,65519,45,65477,87,20,65370,262,65404,65462,92,74,65369,65515,27,74,60,65390,186,65524,59,65428,65529,65495,65483,80,39,65476,87,148,54,119,65437,65478,65403,134,65458,253,65373,65398,65301,43,148,214,183,65535,140,65443,255,65346,65424,65246,65517,65519,313,110,65279,65505,65244,11,65532,65461,65291,65405,65427,65431,11,65355,65273,65194,65358,65188,36,191,65317,9,65266,286,52,213,214,141,65508,127,65490,65209,65362,81,65353,36,42,65377,182,65520,227,65438,65485,65525,302,65432,71,4,184,65480,89,65331,145,152,65487,90,118,214,99,61,77,253,65417,258,65419,86,188,65493,124,65219,65491,65306,65351,65464,308,283,79,65331,294,94,99,142,135,65313,65535,270,65385,54,175,65373,65381,65290,83,25,65236,65441,65359,65385,55,65526,89,65347,117,28,94,65405,65346,65456,77,42,65342,0,65423,65461,65486,361,68,67,65341,65480,418,65330,181,65474,61,65416,65391,65442,34,28,65355,321,128,392,76,226,231,61,65152,65520,36,83,65302,58,65306,325,65474,65376,65367,130,65488,65462,65460,99,65497,88,65369,65410,55,65485,65517,103,23,129,65347,65448,321,65368,2,118,65152,64922,90,65336,228,83,54,65526,3,65332,25,65405,196,228,65465,65510,173,85,65416,65423,479,65287,65410,56,65359,65205,85,75,131,65421,241,321,240,359,65499,298,85,66,138,65535,102,65525,65375,65390,65392,210,301,138,65470};

const uint16_t bitrev512[BITREV512_NPAIRS][2] = {
    {     1,   256 }, {     2,   128 }, {     3,   384 }, {     4,    64 },
    {     5,   320 }, {     6,   192 }, {     7,   448 }, {     8,    32 },
    {     9,   288 }, {    10,   160 }, {    11,   416 }, {    12,    96 },
    {    13,   352 }, {    14,   224 }, {    15,   480 }, {    17,   272 },
    {    18,   144 }, {    19,   400 }, {    20,    80 }, {    21,   336 },
    {    22,   208 }, {    23,   464 }, {    24,    48 }, {    25,   304 },
    {    26,   176 }, {    27,   432 }, {    28,   112 }, {    29,   368 },
    {    30,   240 }, {    31,   496 }, {    33,   264 }, {    34,   136 },
    {    35,   392 }, {    36,    72 }, {    37,   328 }, {    38,   200 },
    {    39,   456 }, {    41,   296 }, {    42,   168 }, {    43,   424 },
    {    44,   104 }, {    45,   360 }, {    46,   232 }, {    47,   488 },
    {    49,   280 }, {    50,   152 }, {    51,   408 }, {    52,    88 },
    {    53,   344 }, {    54,   216 }, {    55,   472 }, {    57,   312 },
    {    58,   184 }, {    59,   440 }, {    60,   120 }, {    61,   376 },
    {    62,   248 }, {    63,   504 }, {    65,   260 }, {    66,   132 },
    {    67,   388 }, {    69,   324 }, {    70,   196 }, {    71,   452 },
    {    73,   292 }, {    74,   164 }, {    75,   420 }, {    76,   100 },
    {    77,   356 }, {    78,   228 }, {    79,   484 }, {    81,   276 },
    {    82,   148 }, {    83,   404 }, {    85,   340 }, {    86,   212 },
    {    87,   468 }, {    89,   308 }, {    90,   180 }, {    91,   436 },
    {    92,   116 }, {    93,   372 }, {    94,   244 }, {    95,   500 },
    {    97,   268 }, {    98,   140 }, {    99,   396 }, {   101,   332 },
    {   102,   204 }, {   103,   460 }, {   105,   300 }, {   106,   172 },
    {   107,   428 }, {   109,   364 }, {   110,   236 }, {   111,   492 },
    {   113,   284 }, {   114,   156 }, {   115,   412 }, {   117,   348 },
    {   118,   220 }, {   119,   476 }, {   121,   316 }, {   122,   188 },
    {   123,   444 }, {   125,   380 }, {   126,   252 }, {   127,   508 },
    {   129,   258 }, {   131,   386 }, {   133,   322 }, {   134,   194 },
    {   135,   450 }, {   137,   290 }, {   138,   162 }, {   139,   418 },
    {   141,   354 }, {   142,   226 }, {   143,   482 }, {   145,   274 },
    {   147,   402 }, {   149,   338 }, {   150,   210 }, {   151,   466 },
    {   153,   306 }, {   154,   178 }, {   155,   434 }, {   157,   370 },
    {   158,   242 }, {   159,   498 }, {   161,   266 }, {   163,   394 },
    {   165,   330 }, {   166,   202 }, {   167,   458 }, {   169,   298 },
    {   171,   426 }, {   173,   362 }, {   174,   234 }, {   175,   490 },
    {   177,   282 }, {   179,   410 }, {   181,   346 }, {   182,   218 },
    {   183,   474 }, {   185,   314 }, {   187,   442 }, {   189,   378 },
    {   190,   250 }, {   191,   506 }, {   193,   262 }, {   195,   390 },
    {   197,   326 }, {   199,   454 }, {   201,   294 }, {   203,   422 },
    {   205,   358 }, {   206,   230 }, {   207,   486 }, {   209,   278 },
    {   211,   406 }, {   213,   342 }, {   215,   470 }, {   217,   310 },
    {   219,   438 }, {   221,   374 }, {   222,   246 }, {   223,   502 },
    {   225,   270 }, {   227,   398 }, {   229,   334 }, {   231,   462 },
    {   233,   302 }, {   235,   430 }, {   237,   366 }, {   239,   494 },
    {   241,   286 }, {   243,   414 }, {   245,   350 }, {   247,   478 },
    {   249,   318 }, {   251,   446 }, {   253,   382 }, {   255,   510 },
    {   259,   385 }, {   261,   321 }, {   263,   449 }, {   265,   289 },
    {   267,   417 }, {   269,   353 }, {   271,   481 }, {   275,   401 },
    {   277,   337 }, {   279,   465 }, {   281,   305 }, {   283,   433 },
    {   285,   369 }, {   287,   497 }, {   291,   393 }, {   293,   329 },
    {   295,   457 }, {   299,   425 }, {   301,   361 }, {   303,   489 },
    {   307,   409 }, {   309,   345 }, {   311,   473 }, {   315,   441 },
    {   317,   377 }, {   319,   505 }, {   323,   389 }, {   327,   453 },
    {   331,   421 }, {   333,   357 }, {   335,   485 }, {   339,   405 },
    {   343,   469 }, {   347,   437 }, {   349,   373 }, {   351,   501 },
    {   355,   397 }, {   359,   461 }, {   363,   429 }, {   367,   493 },
    {   371,   413 }, {   375,   477 }, {   379,   445 }, {   383,   509 },
    {   391,   451 }, {   395,   419 }, {   399,   483 }, {   407,   467 },
    {   411,   435 }, {   415,   499 }, {   423,   459 }, {   431,   491 },
    {   439,   475 }, {   447,   507 }, {   463,   487 }, {   479,   503 },
};

// these are scaled by R so that montmul can be used
const uint16_t ntt512_inv_omega_powers_rev[512] = {
 0, 4091, 4091, 7888, 4091, 7888, 1229, 1081, 4091, 7888, 1229, 1081, 4342, 5329, 2530, 6275, 4091, 7888, 1229, 1081, 4342, 5329, 2530, 6275, 2812, 7023, 6399, 10698, 2579, 7538, 11703, 6464, 4091, 7888, 1229, 1081, 4342, 5329, 2530, 6275, 2812, 7023, 6399, 10698, 2579, 7538, 11703, 6464, 4615, 7099, 6442, 8546, 1711, 965, 5882, 1134, 9180, 2125, 1364, 10329, 4189, 10414, 1688, 10404, 4091, 7888, 1229, 1081, 4342, 5329, 2530, 6275, 2812, 7023, 6399, 10698, 2579, 7538, 11703, 6464, 4615, 7099, 6442, 8546, 1711, 965, 5882, 1134, 9180, 2125, 1364, 10329, 4189, 10414, 1688, 10404, 3412, 4431, 9460, 5831, 5664, 4042, 9725, 7144, 7506, 7882, 1549, 7072, 12172, 997, 79, 6049, 12275, 8417, 1690, 7446, 2181, 6308, 3569, 5719, 1237, 1538, 12189, 432, 8306, 4426, 1534, 4679, 4091, 7888, 1229, 1081, 4342, 5329, 2530, 6275, 2812, 7023, 6399, 10698, 2579, 7538, 11703, 6464, 4615, 7099, 6442, 8546, 1711, 965, 5882, 1134, 9180, 2125, 1364, 10329, 4189, 10414, 1688, 10404, 3412, 4431, 9460, 5831, 5664, 4042, 9725, 7144, 7506, 7882, 1549, 7072, 12172, 997, 79, 6049, 12275, 8417, 1690, 7446, 2181, 6308, 3569, 5719, 1237, 1538, 12189, 432, 8306, 4426, 1534, 4679, 6180, 2796, 10637, 10086, 1053, 3316, 11578, 7004, 10469, 489, 10787, 9438, 883, 8966, 9277, 6130, 1156, 10736, 900, 8401, 11269, 9322, 10772, 7045, 4949, 4673, 4746, 9974, 9368, 6720, 10270, 12163, 3403, 5453, 13, 5351, 11455, 4586, 9386, 4676, 9179, 3604, 8507, 2083, 3467, 9109, 9843, 4668, 10078, 1195, 1808, 4970, 1228, 2560, 2742, 12241, 1367, 5892, 5274, 3269, 3854, 2030, 10527, 730, 4091, 7888, 1229, 1081, 4342, 5329, 2530, 6275, 2812, 7023, 6399, 10698, 2579, 7538, 11703, 6464, 4615, 7099, 6442, 8546, 1711, 965, 5882, 1134, 9180, 2125, 1364, 10329, 4189, 10414, 1688, 10404, 3412, 4431, 9460, 5831, 5664, 4042, 9725, 7144, 7506, 7882, 1549, 7072, 12172, 997, 79, 6049, 12275, 8417, 1690, 7446, 2181, 6308, 3569, 5719, 1237, 1538, 12189, 432, 8306, 4426, 1534, 4679, 6180, 2796, 10637, 10086, 1053, 3316, 11578, 7004, 10469, 489, 10787, 9438, 883, 8966, 9277, 6130, 1156, 10736, 900, 8401, 11269, 9322, 10772, 7045, 4949, 4673, 4746, 9974, 9368, 6720, 10270, 12163, 3403, 5453, 13, 5351, 11455, 4586, 9386, 4676, 9179, 3604, 8507, 2083, 3467, 9109, 9843, 4668, 10078, 1195, 1808, 4970, 1228, 2560, 2742, 12241, 1367, 5892, 5274, 3269, 3854, 2030, 10527, 730, 7630, 8821, 625, 9589, 3388, 3060, 8846, 4551, 1730, 9731, 5344, 10340, 7871, 8763, 11911, 6057, 1467, 5460, 3736, 4506, 2320, 9640, 6101, 9036, 9948, 9130, 8723, 2133, 5680, 4956, 6038, 3901, 3585, 6633, 2621, 6865, 7680, 8605, 12145, 4063, 5387, 8188, 9807, 8756, 6090, 727, 2190, 5286, 10812, 9330, 6249, 11346, 2749, 1888, 1715, 7338, 1469, 2502, 1739, 8709, 3764, 12250, 2080, 8219, 673, 42, 10049, 7219, 6635, 5746, 4868, 1582, 4614, 8578, 1296, 300, 989, 11949, 1748, 7687, 11357, 2060, 8927, 7642, 2991, 351, 5858, 12052, 12126, 7586, 9143, 7692, 5204, 8487, 2053, 11285, 8780, 3853, 7516, 5381, 10325, 4552, 7103, 1758, 3698, 11552, 6536, 4699, 3243, 8602, 16, 914, 6375, 9327, 6409, 8197, 6664, 12011, 6634, 7225, 2895, 7156, 3402, 6932, 1060, 5252, 10733, 3281};

 const uint16_t ntt512_mixed_powers_rev[512] = {
  0, 4401, 11208, 11060, 6014, 9759, 6960, 7947, 5825, 586, 4751, 9710, 1591, 5890, 5266, 9477, 1885, 10601, 1875, 8100, 1960, 10925, 10164, 3109, 11155, 6407, 11324, 10578, 3743, 5847, 5190, 7674, 7610, 10755, 7863, 3983, 11857, 100, 10751, 11052, 6570, 8720, 5981, 10108, 4843, 10599, 3872, 14, 6240, 12210, 11292, 117, 5217, 10740, 4407, 4783, 5145, 2564, 8247, 6625, 6458, 2829, 7858, 8877, 11559, 1762, 10259, 8435, 9020, 7015, 6397, 10922, 48, 9547, 9729, 11061, 7319, 10481, 11094, 2211, 7621, 2446, 3180, 8822, 10206, 3782, 8685, 3110, 7613, 2903, 7703, 834, 6938, 12276, 6836, 8886, 126, 2019, 5569, 2921, 2315, 7543, 7616, 7340, 5244, 1517, 2967, 1020, 3888, 11389, 1553, 11133, 6159, 3012, 3323, 11406, 2851, 1502, 11800, 1820, 5285, 711, 8973, 11236, 2203, 1652, 9493, 6109, 9008, 1556, 7037, 11229, 5357, 8887, 5133, 9394, 5064, 5655, 278, 5625, 4092, 5880, 2962, 5914, 11375, 12273, 3687, 9046, 7590, 5753, 737, 8591, 10531, 5186, 7737, 1964, 6908, 4773, 8436, 3509, 1004, 10236, 3802, 7085, 4597, 3146, 4703, 163, 237, 6431, 11938, 9298, 4647, 3362, 10229, 932, 4602, 10541, 340, 11300, 11989, 10993, 3711, 7675, 10707, 7421, 6543, 5654, 5070, 2240, 12247, 11616, 4070, 10209, 39, 8525, 3580, 10550, 9787, 10820, 4951, 10574, 10401, 9540, 943, 6040, 2959, 1477, 7003, 10099, 11562, 6199, 3533, 2482, 4101, 6902, 8226, 144, 3684, 4609, 5424, 9668, 5656, 8704, 8388, 6251, 7333, 6609, 10156, 3566, 3159, 2341, 3253, 6188, 2649, 9969, 7783, 8553, 6829, 10822, 6232, 378, 3526, 4418, 1949, 6945, 2558, 10559, 7738, 3443, 9229, 8901, 2700, 11664, 3468, 4659, 11036, 2452, 9478, 8502, 10432, 6233, 728, 7569, 5200, 10175, 9410, 6242, 10492, 8950, 9817, 6034, 10438, 2818, 408, 1271, 11929, 8276, 6911, 9210, 5475, 11363, 2936, 4327, 6084, 2688, 7323, 4108, 1361, 9812, 9340, 1024, 9108, 1988, 5800, 478, 2806, 8681, 1911, 12188, 3374, 812, 292, 1753, 3619, 6786, 7707, 6750, 9826, 7056, 8470, 4639, 11344, 3291, 1244, 8815, 1071, 11017, 4325, 6395, 5150, 9959, 3884, 5473, 2356, 6737, 1333, 5267, 11277, 2510, 721, 9505, 4424, 5348, 5737, 5613, 105, 7827, 6689, 386, 12170, 8334, 10443, 10213, 4370, 11505, 8617, 850, 3240, 11539, 11535, 3133, 3488, 9661, 6501, 4981, 11613, 7894, 7379, 909, 40, 10004, 1963, 3073, 4051, 6686, 9245, 7987, 8399, 10231, 2650, 11448, 8505, 7248, 1093, 6688, 4296, 371, 4371, 695, 9878, 10230, 9793, 7405, 2609, 12254, 4225, 5963, 2778, 4136, 11597, 8808, 3835, 6736, 8476, 1224, 12039, 11209, 9237, 8444, 4933, 8530, 11361, 3856, 5879, 6718, 1871, 2184, 6342, 3311, 5852, 3652, 10017, 6898, 6476, 4873, 11603, 5393, 3816, 3213, 2416, 9454, 10422, 3732, 4220, 10857, 4328, 10832, 3410, 4900, 10661, 832, 7431, 4083, 9217, 3442, 6325, 2746, 10855, 5111, 10824, 8418, 303, 5733, 9853, 10122, 7030, 876, 2262, 2890, 2250, 9720, 2352, 821, 9739, 1273, 1097, 315, 11131, 7778, 11865, 11932, 6228, 6751, 6990, 3161, 8159, 11652, 4367, 7068, 8777, 3999, 4759, 9253, 8352, 2163, 8534, 983, 7739, 4922, 7488, 2363, 6177, 5056, 11176, 599, 10204, 824, 6174, 619, 2523, 7950, 2834, 937, 4514, 3279, 7884, 10464, 9635, 7214, 896, 10261, 9562, 9848, 6855, 120, 3070, 5889, 4520, 12153, 617, 3157
};

void shuffle_with_table(uint16_t *a, const uint16_t p[][2], uint32_t n) {
  uint32_t i, j, k;
  int32_t x;

  for (i=0; i<n; i++) {
    j = p[i][0];
    k = p[i][1];
    x = a[j]; a[j] = a[k]; a[k] = x;
  }
}

static void ntt512_bitrev_shuffle(uint16_t *a) {
  shuffle_with_table(a, bitrev512, BITREV512_NPAIRS);
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

static void
mq_poly_montymul_ntt2(uint16_t *f, const uint16_t *g, unsigned logn) {
    size_t u, n;

    n = (size_t)1 << logn;
    for (u = 0; u < n; u ++) {
        uint16_t temp = mq_montymul(f[u], R2);
        f[u] = (uint16_t)mq_montymul(temp, g[u]);
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

void mulntt_ct_std2rev(uint16_t *a, uint32_t n, const uint16_t *p) {
  uint32_t j, s, t, u, d;
  uint32_t x, w;

  d = n;
  for (t=1; t<n; t <<= 1) {
    d >>= 1;
    /*
     * Invariant: d * 2t = n.
     *
     * Each iteration produces d blocks of size 2t.
     * Block i is stored at indices {i, i+d, ..., i+d*(2t-1) } in
     * bit-reverse order.
     *
     * For round t:
     *    w_t = omega^(n/2t)
     *  psi_t = psi^(n/2t)
     * For a given j between 0 and t-1
     *   w_t,j = psi_t * w_t^bitrev(j)
     */
    for (j=0, u=0; j<t; j++, u+=2*d) { // u = j * 2d
      w = p[t + j]; // psi_t * w_t^bitrev(j)
      for (s=u; s<u+d; s++) {
        x = mq_montymul(a[s + d], w);
        a[s + d] = mq_sub(a[s], x);
        a[s] = mq_add(a[s], x);
      }
    }
  }
}

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

static void
mq_poly_tomonty(uint16_t *f, unsigned logn) {
    size_t u, n;

    n = (size_t)1 << logn;
    for (u = 0; u < n; u ++) {
        f[u] = (uint16_t)mq_montymul(f[u], R2);
    }
}

uint16_t factors[] = {128, 2034, 1215, 5674, 11437, 8735, 8426, 6012, 4135, 7527, 12272, 1458, 4351, 6351, 10482, 280, 12130, 4962, 1659, 7353, 9123, 7679, 10079, 5205, 336, 2267, 10870, 11822, 3908, 6032, 6757, 9637, 6246, 2861, 7636, 755, 6813, 12063, 12154, 735, 4191, 9953, 5891, 11621, 906, 3260, 9560, 12127, 882, 7487, 7028, 9527, 4114, 3545, 3912, 11472, 7179, 5974, 1611, 3518, 4059, 2479, 4254, 9610, 6393, 6157, 4711, 4391, 11595, 2413, 517, 2647, 11532, 2756, 15, 8111, 7727, 1625, 10269, 5536, 8092, 6465, 5765, 18, 12191, 1899, 1950, 9865, 9101, 2337, 7758, 6918, 7395, 4798, 12110, 2340, 11838, 1090, 7720, 4394, 3386, 8874, 842, 2243, 2808, 9290, 1308, 9264, 2815, 6521, 8191, 5926, 10065, 10743, 11148, 8943, 8659, 3378, 10283, 12287, 9569, 12078, 7976, 8462, 5816, 7933, 11427, 7424, 7371, 9025, 9578, 12029, 2781, 9437, 4604, 6339, 6451, 11303, 10830, 6578, 11977, 5795, 3951, 3067, 5149, 10199, 8648, 707, 2978, 6999, 6954, 7199, 8596, 3721, 9781, 5462, 5764, 10947, 5941, 5887, 6181, 484, 6923, 1906, 11470, 4459, 5763, 9587, 11980, 9875, 10412, 3392, 4745, 1475, 2893, 2000, 4131, 2087, 11850, 5121, 8986, 5694, 1770, 10845, 2400, 7415, 7420, 1931, 8603, 952, 4375, 2124, 725, 2880, 8898, 8904, 4775, 5408, 6058, 5250, 91, 870, 3456, 5762, 8227, 5730, 1574, 2354, 6300, 2567, 1044, 6605, 11830, 2499, 6876, 11720, 367, 7560, 7996, 11084, 7926, 1907, 541, 10709, 1775, 5356, 9072, 12053, 10843, 11969, 7204, 3107, 10393, 2130, 8885, 3513, 9548, 8096, 11905, 6187, 8644, 7556, 2556, 10662, 11589, 6542, 12173, 1997, 51, 7915, 11525, 5525, 5421, 11449, 477, 9692, 7312, 2519, 9498, 1541, 6630, 8963, 11281, 5488, 4257, 1401, 565, 6482, 4307, 7956, 5840, 3706, 1670, 10024, 4139, 678, 405, 10084, 12005, 7008, 6905, 2004, 9571, 2509, 8187, 486, 9643, 2117, 3494, 8286, 12236, 1654, 553, 2451, 3041, 6656, 7456, 1735, 112, 4852, 11816, 8037, 5399, 6107, 10445, 11405, 2082, 5050, 10738, 4348, 2271, 4021, 12244, 245, 1397, 7414, 6060, 7970, 302, 5183, 7283, 12235, 294, 6592, 6439, 7272, 9564, 5278, 1304, 3824, 2393, 10184, 537, 5269, 1353, 9019, 1418, 11396, 2131, 10245, 9763, 5560, 3865, 8997, 8365, 9075, 3844, 5015, 5, 6800, 6672, 4638, 3423, 10038, 10890, 2155, 6018, 6, 8160, 633, 650, 11481, 7130, 779, 2586, 2306, 2465, 9792, 8133, 780, 3946, 8556, 10766, 5561, 5225, 2958, 4377, 4844, 936, 7193, 436, 3088, 9131, 6270, 10923, 10168, 3355, 3581, 3716, 2981, 11079, 1126, 7524, 8192, 7286, 4026, 6755, 6917, 6035, 10837, 3809, 6571, 2457, 11201, 7289, 8106, 927, 7242, 5631, 2113, 10343, 7864, 3610, 6289, 12185, 6028, 1317, 9215, 9909, 7496, 6979, 4332, 5089, 2333, 2318, 6496, 11058, 9433, 11453, 5917, 10114, 3649, 10173, 10155, 10253, 8354, 6404, 8828, 12016, 9679, 1921, 7292, 12186, 7388, 7567, 5227, 5678, 4588, 9157, 4763, 1377, 4792, 3950, 1707, 11188, 1898, 590, 3615, 800, 6568, 10666, 4740, 6964, 8510, 9651, 708, 4338, 960, 2966, 2968, 5688, 5899, 10212, 1750, 8223, 290, 1152, 6017, 10935, 1910, 4621, 4881, 2100, 4952, 348, 6298, 12136, 833, 2292, 8003, 8315, 2520, 10858, 7791, 2642, 4732, 8373, 7666, 4688, 9978, 3024, 8114, 11807, 8086, 10594, 5132, 11657, 710, 7058, 1171, 7279, 6795};

int
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
    // print_uint16_array(stdout, h, 512);
    // print_uint16_array(stdout, tt, 512);

    mulntt_ct_std2rev(h, 512, ntt512_mixed_powers_rev);
    // mq_poly_tomonty(h, logn);

    mulntt_ct_std2rev(tt, 512, ntt512_mixed_powers_rev);

    mq_poly_montymul_ntt2(tt, h, logn);

    // we need to shuffle the input
    ntt512_bitrev_shuffle(tt);
    mulntt_ct_std2rev(tt, 512, ntt512_inv_omega_powers_rev);
    // shuffle the output
    ntt512_bitrev_shuffle(tt);
    // then scale the ouput
    mq_poly_montymul_ntt(tt, factors, logn);
  
    // this should end up doing poly multiplication 
    // print_uint16_array(stdout, tt, 512);

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

    // // check against the reference result
    // for (u = 0; u < 512; u ++) {
    //     assert(tt[u] == buff_tt[u]);
    // }

    /*
     * Signature is valid if and only if the aggregate (-s1,s2) vector
     * is short enough.
     */
    return PQCLEAN_FALCON512_CLEAN_is_short((int16_t *)tt, s2, logn);
}

// int main(void) {
//     uint8_t tmp[FALCON_KEYGEN_TEMP_9];

//     uint16_t buff_c0[] = {6673,10315,10940,3299,4987,5662,11800,9550,2694,7285,10708,9271,5302,10252,6550,4379,4864,610,7943,7824,5114,1447,6056,10284,11092,134,9036,3609,1300,12158,3845,9665,9733,1286,2694,3234,11398,5564,3406,1286,1931,8562,9165,1804,5996,11429,10552,6082,5037,7371,1689,12099,114,4137,5378,10635,6542,949,7802,9975,7195,4071,5425,9455,7531,139,11058,3459,6055,3991,11095,3331,9444,2786,2748,12130,10999,3562,7589,11383,11600,7646,8820,6571,13,1737,12199,5000,11779,4521,9776,3389,10782,8206,151,4370,7577,5380,501,6168,8233,9495,4724,3681,10087,8825,639,331,2216,5575,578,12232,6630,2559,3943,6350,1147,1979,7196,12003,1990,1946,11435,4858,1823,2570,5424,4417,10835,230,7174,6230,3965,7457,7365,6346,11573,7818,5093,10342,3646,11570,10541,1032,1714,11984,1599,2658,7471,3183,4841,1487,6818,6149,59,4224,11243,8476,10957,4761,6515,4821,4695,8327,3346,816,8069,10736,9283,7802,9985,12079,2597,9995,4482,6078,5882,3901,10058,10522,2821,2967,2082,9161,2133,2091,12077,3077,2426,7337,8708,6529,4377,5990,11895,5074,11521,8196,3455,7557,8214,6193,225,6541,5001,8846,4592,7685,4887,1958,4335,11441,5325,5959,802,7885,4183,2282,8597,4655,6144,2393,3354,1892,4025,5517,8980,5598,3140,3632,769,351,205,11781,2038,4797,271,9645,9006,681,8735,1765,5566,4225,10729,8154,12210,11994,8839,3632,7146,3860,1842,6456,2263,3770,2108,7291,2141,8070,8768,5603,12278,8039,3818,7992,6229,10915,2514,9612,9591,3061,1820,9580,12023,137,4519,5137,9208,4363,7112,2069,8425,11266,10784,12254,7314,14,6773,10897,6175,3446,8319,131,5493,9103,3454,10593,1849,10906,6904,3968,5873,913,1569,6431,7643,1451,3955,5784,5521,7948,5371,549,4727,6231,10299,980,11328,4806,619,182,1241,2903,1555,9013,9358,3462,4332,839,3895,469,5210,7597,7962,9497,10476,7109,2908,6482,5191,2153,6025,7581,7426,4571,4299,3812,3498,7244,4274,2022,8859,1670,12263,7258,7447,6788,2368,3473,10732,11379,11349,4244,144,11120,3583,11084,10320,7677,3648,11926,1727,5563,4196,9718,6620,959,1427,10017,4524,5386,1855,8744,3044,8480,9773,10804,7236,10273,2600,9864,2883,12040,5423,11087,8480,3826,8325,2103,2023,5979,9077,5463,7261,7750,10123,6595,7930,3869,12113,11,7509,4414,9764,5654,2063,592,4909,7381,11924,5296,678,11707,9237,5175,11937,2000,1783,6735,7838,6899,6358,8466,10072,4448,431,11900,7165,11098,1484,6558,9408,1946,12235,2949,9597,5259,11990,4477,10820,954,2897,3795,12120,7465,4025,10707,2944,8986,9069,8695,11418,7097,3889,995,2041,8724,12215,942,2300,11281,10910,8256,8645,5329,5550,4095,8297,6398,1056,5408,4645,1146,6612,12199,2656,6493,4550,5902,6539,2743,7884,11490,3665,6152,5200,556,6490,571,794,9852,1811,5973,10142,3747,9328,3682,7614,4133,7798,3711};
//     uint16_t buff_h[] = {308,5674,2938,937,513,10228,10316,6784,3124,10820,1141,4726,12037,11917,11696,2060,2858,10057,9324,2319,2888,5145,371,5961,9647,11284,4746,7851,8011,7430,7519,10929,2904,596,10283,10505,3605,11360,3900,4296,6396,5344,2473,11273,4427,10534,6248,5018,9514,11213,11410,10591,10688,4771,7718,11389,6483,7925,1610,8049,98,3983,7269,1263,1294,11419,402,3386,9792,8966,2191,1697,135,4170,11940,1255,7542,5118,8403,3113,8999,3774,3450,11821,7942,1541,11389,7729,10750,12163,4382,9027,8877,12236,11169,2378,7923,3740,7507,7693,6020,5349,8301,1283,11198,1685,4745,1141,368,4269,7860,12200,6433,1943,749,6428,6449,5457,7078,2430,6211,6731,1848,4943,10122,6667,2740,3668,9643,4512,6103,1199,8768,670,5246,6441,7479,4692,6742,11512,2859,11844,7075,7202,11946,5616,3872,11261,8679,11798,5728,8072,2773,5138,2052,6537,5566,4719,8474,8630,11562,7286,10423,5567,4631,1875,9842,11844,6385,8223,11709,3788,9957,783,4445,3084,6571,11340,10118,5374,7923,10385,9753,3522,5145,5827,535,12169,2679,6849,9451,8172,6463,7946,7227,2909,2713,9886,2775,9894,7635,9709,4547,4599,129,3773,5869,11848,8187,6147,8436,7398,5721,3849,9164,3697,4975,3479,7509,1618,5712,6599,3697,189,3953,9253,7503,7633,6416,8057,1428,221,9371,8131,1888,11280,8952,9997,11818,8758,8760,10835,267,11251,1360,11675,417,6464,3134,4128,8966,10097,5584,3967,10668,5433,7370,3552,4568,5922,12184,9928,9256,10187,7470,7895,6469,10796,8526,8869,8525,4655,8865,9896,9514,2426,12121,6146,10130,6862,6293,6967,9197,8375,9187,7781,5827,147,8572,11116,10371,8106,9270,3685,8636,533,8596,6148,12270,9751,3693,3460,9934,9899,2857,9816,2526,8895,11004,2559,7380,7372,1741,4345,10756,3202,148,10513,11460,649,3081,11077,774,3907,4145,6951,11026,6090,11338,11340,6319,3316,5232,10784,6202,629,4776,959,11773,6858,1944,6529,7290,10946,2938,7897,5582,11495,8738,9329,5117,4659,8927,11602,2969,7196,1799,4967,6529,6382,9194,5136,4863,2179,4237,6763,2864,7202,11662,3419,5327,10109,4404,662,11953,1663,9576,11623,11832,6337,5235,4237,12262,5452,8358,1908,3727,3960,2164,2351,3679,2455,5285,10959,11242,7442,3629,5474,4908,2905,6379,3080,1658,10599,10743,11096,12063,10721,9675,4995,11614,1645,6427,3228,5132,10619,6031,1508,5885,5535,66,1672,11467,4029,5678,9628,7434,9673,8710,8657,3637,6590,1454,11765,846,2792,7187,5235,3005,6414,11054,7313,5880,528,369,9388,11768,1215,2590,7761,484,2214,11229,1028,5115,8868,12266,10812,7880,5108,8717,9361,3242,7185,1069,2801,10923,8266,10663,8701,187,3233,2343,8827,8903,10803,2006,10098,1306,11329,5315,11430,7683,6331,11304,1334,4542,4513,9917,1260,9488,2105,950,2622,287,11985,1009,5567,8205,2044,5968,8808,6339,4580,10256,2134,1182,3976,1977,50,2688,1143};
//     int16_t buff_s2[] = {-211,39,56,180,-287,-64,-142,-178,-197,-53,262,196,86,0,-100,124,-116,-38,152,155,34,226,114,105,69,329,26,28,-92,35,-131,17,124,-298,-159,-140,168,-157,-181,2,174,58,-142,32,-142,-280,-95,-70,215,-277,-157,-43,17,2,448,-30,557,-93,12,285,-163,61,-114,125,188,-139,160,203,-423,67,-187,0,273,82,-6,-212,186,167,41,96,238,139,9,-97,-246,-89,29,68,172,-100,175,-149,-137,-66,121,-30,2,-62,-140,277,-18,280,70,-153,385,-356,484,29,74,145,138,53,-141,184,136,57,126,-140,132,-12,-224,222,-199,-140,44,-182,58,-194,24,-263,-5,-148,47,138,324,-143,182,-124,-32,-57,79,161,84,-130,116,228,-14,-114,-25,89,-120,129,264,11,67,-110,-162,-229,-244,-27,7,-209,139,-157,65,-102,-55,123,-295,-258,-104,-145,77,-7,-79,-30,-77,226,-121,2,-139,-29,-161,198,-139,3,-194,-49,179,113,-81,-2,-41,-118,-61,-208,-67,28,150,-169,-145,304,33,22,159,255,-84,-182,-376,264,57,206,65,44,169,-26,51,-306,-200,-183,-436,214,226,-56,-71,43,-207,136,67,319,-48,-130,132,117,110,-326,-13,-169,-48,-176,-314,-142,-217,-100,-13,-38,-26,-294,-47,227,89,175,-173,42,117,-93,-47,-29,19,100,-61,-185,-202,187,66,40,72,50,-12,-16,-161,238,8,-150,-17,-168,-36,80,47,-89,98,-179,117,317,-261,376,18,-40,10,44,-115,121,174,-361,214,-111,129,-63,-214,471,23,-128,199,-95,-184,-198,74,-127,160,-336,76,-159,-19,-232,-9,16,128,175,49,-91,68,-180,-42,-51,-53,-43,84,155,53,190,-96,-113,-66,-42,-230,134,249,-95,-280,-25,-123,5,-176,310,-195,149,53,197,38,-150,300,-13,62,-73,160,-185,52,-168,-33,74,310,-83,28,-338,-148,-41,115,-64,124,-6,-135,-37,-23,-92,132,-82,-122,123,236,35,57,198,159,133,-127,139,166,-95,-142,-102,-39,32,-171,119,14,177,10,128,219,5,1,27,-40,191,-66,-118,-116,41,-218,-46,276,-27,-145,86,-162,86,-156,120,58,103,173,-65,-175,45,-7,-146,158,53,15,-212,-111,223,503,-21,214,85,179,82,61,-84,77,98,106,278,-23,169,-119,-443,-3,220,98,141,250,7,37,-36,99,58,-88,46,130,-305,161,269,-25,47,-260,94,28,146,-252,-123,-292,-65,-68,-244,-238,87,-229,-125,216,-38,-81,288,-225,-135,300,-191,-84,214,-133,62,-78,438,114,-74,-242,-182,142,-72,-244,4,-186,-68,-192,-191,335,52,85,97,91,16};

//     int32_t verify = PQCLEAN_FALCON512_CLEAN_verify_raw(buff_c0, buff_s2, buff_h, 9, tmp);
//   return 0;
// }
