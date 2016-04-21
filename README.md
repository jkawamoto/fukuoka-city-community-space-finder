Fukuoka City Community Space Finder
=====================================
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)
[![npm version](https://badge.fury.io/js/fukuoka-city-community-space-finder.svg)](https://badge.fury.io/js/fukuoka-city-community-space-finder)
[![Code Climate](https://codeclimate.com/github/jkawamoto/fukuoka-city-community-space-finder/badges/gpa.svg)](https://codeclimate.com/github/jkawamoto/fukuoka-city-community-space-finder)

Find Community Spaces in Fukuoka City and check reservation status of them.
If you want to try it as a stand-alone command, see *Running as a stand-alone command* section.

Install
----------
```sh
$ npm install fukuoka-city-community-space-finder
```

Usage
--------
This library provides four methods; `area`, `building`, `institution`,
and `status`. The former three methods are for finding community spaces.
Fukuoka City is separated into several area. `area` returns such area names.
Each area has some buildings, such community centre, sports centre, etc.
`building` returns those buildings in a given area.

```js
var finder = require("fukuoka-city-community-space-finder");

// Find areas.
finder.area().then(function(res){
  console.log(res);
});
// -> [ '中央区', '博多区', '東区', '西区', '南区', '城南区', '早良区' ]

// Find buildings in an area.
finder.building("中央区").then(function(res) {
  console.log(res);
});
// -> [ '舞鶴公園', '平和中央公園', '中央体育館', '市民会館',
//      '福岡市文学館（赤煉瓦文化館）', '健康づくりサポートセンター',
//      'ＮＰＯボランティア交流センター', '中央市民センター' ]

// Find institutions in a building (space).
finder.institution("中央区", "舞鶴公園").then(function(res) {
  console.log(res);
});
// -> [ '野球場', 'テニスコート１', '球技場' ]
```

The last method `status` checks reservation status of an institution in a week,
which means checking the institution is already occupied, available, or
in maintenance, etc.

```js
var finder = require("fukuoka-city-community-space-finder");

finder.status("中央区", "舞鶴公園", "野球場", 2016, 4, 25).then(
  function(res) {
    console.log(JSON.stringify(res));
  }
);
```

The output of `status` method is an object and the result of the above sample
is as follows.

```json
{
  "04/25(月)": {
    "６００": "closed",
    "９００": "available",
    "１１００": "available",
    "１３００": "available",
    "１５００": "occupied",
    "１７００": "occupied"
  },
  ...
}
```

However, there is another type of results for complex institutions. For example, if you ask as

```js
var finder = require("fukuoka-city-community-space-finder");

finder.status("中央区", "舞鶴公園", "テニスコート１", 2016, 4, 25).then(
  function(res) {
    console.log(JSON.stringify(res));
  }
);
```

you will receive the following result.

```json
{
  "テニスコート１": {
    "04/25(月)": {
      "06:00-19:00": "available"
    },
    ...
  },
  "テニスコート２": {
    "04/25(月)": {
      "06:00-10:00": "available",
      "10:00-12:00": "occupied",
      "12:00-19:00": "available"
    },
    ...
  },
  ...
}
```


Method
-------
### area()
Returns a list of areas in Fukuoka city.

#### Returns
A Promise object which returns a list of areas in Fukuoka city.


### building(area)
Returns a list of buildings in a given area.

#### Args
* area: name of the area.

#### Returns
A Promise object which returns a list of buildings in the area.


### institution(area, building)
Returns a list of institutions in a given area and building.

#### Args
* area: name of the area.
* building: name of the building.

#### Returns
A Promise object which returns a list of institutions.


### status(area, building, institution, year, month, day)
Search reservation statuses of a given institution in a given date.

#### Args
* area: area name obtained by area method.
* building: building name obtained by building method.
* institution: institution name obtained by institution method.
* year: Year.
* month: Month.
* day: Day.

#### Returns
A Promise object hich returns the result via then method.

### Error
Sometimes some error happens, in most of cases it is because of internet speed
or server's traffic.
At first, you should try again.


Running as a stand-alone command
-----------------------------------
This module provides `csf` command for stand-alone running.
To install the command globally, run

```sh
$ npm install -g fukuoka-city-community-space-finder
```

now you can use `csf` command.

~~~
Usage: csf <command> [options]

Commands:
  area         List up areas.
  building     List up buildings in an area.
  institution  List up institutions in a building
  state        Search reservation status.

Options:
  --help  Show help                                                    [boolean]
~~~

Each command is related to same name function.

### area
Show the list of areas.

~~~
csf area

Options:
  --help  Show help                                                    [boolean]
~~~

### building
Show a list of buildings in an area.

~~~
csf building

Options:
  --help  Show help                                                    [boolean]
  --area  Name of area.
~~~

### institution
Show a list of institutions in a building.

~~~
csf institution

Options:
  --help      Show help                                                [boolean]
  --area      Name of area.                                           [required]
  --building  Name of building.                                       [required]
~~~

### state
Search reservation status. 

~~~
csf state

Options:
  --help         Show help                                             [boolean]
  --area         Name of area.                                        [required]
  --building     Name of building.                                    [required]
  --institution  Name of institution.                                 [required]
  --year         Year.                                          [default: today]
  --month        Month.                                         [default: today]
  --day          Day.                                           [default: today]
~~~

License
--------
This software is released under the MIT License, see [LICENSE](LICENSE).

Acknowledgement
----------------
This project is partly supported by [BigData & OpenData Initiative in Kyushu](http://www.bodik.jp/).
