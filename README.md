# health-app

> A simple Shiny dashboard for tracking metrics related to my health.

## Installation

Currently this is just a very basic Shiny app.  There isn't much installation other than cloning the repo to your machine, ensuring everything is setup (see below), and then running `runApp(health-app)` from within the R console.  **Frankly, the calling this an "app" is generous and it is not nearly ready for flexible use by others.**

### Setup and Usage

1. Clone the repo to your local machine into a directory of your choosing.  For me, this is `~/DSwork/`.
2. Ensure their is a csv file in the `/data` subdirectory of the `health-app`.  E.g. `~/DSwork/data/health-metrics.csv`.
3. Currently the app expects a `.csv` with *exactly* 8 columns containing the following information:
- Date
- Weight
- Body_Fat
- Protein
- Fat
- Carbs
- Kcal_Input
- Kcal_Output
4. Return to the parent director and `runApp("health-app")`.
5. Expect failure.

---

## Features
Currently the app reads in a `.csv` of health-related metrics.  This csv is populated from 3 sources:

1. Body weight and body fat percentage from the Health Mate App

2. Total calories consumed from the MyFitnessPal App

3. Total calories expended from the Apple Fitness App

The app uses this data to create several additional calculated fields:

1. Calorie deficit/surplus based on calories consumed and expended

2. Moving averages for weight, body fat, calories consumed, calories expended, and calorie deficit/surplus

The user can then input new values which will be appended to the existing file and saved out separately. The user can also adjust the period used for the moving average. 

## Future Plans
1. More flexible file input.  I think passing a list of columns names to import from the file should work.

2. Specifying the file to input instead of looking in one specific location.

3. More visuals on how the data relate.  A simple correlation matrix 

3. Make programmatic calls to Health Mate App. Seems highly challenging but doable. More info <a href="https://developer.withings.com/oauth2/#section/Overview/Withings-API-list" target="_blank"> `here.` </a>

4. Make programmatic calls to MyFitnessPal App.  Seems simple enough using some Python from <a href="https://github.com/coddingtonbear/python-myfitnesspal" target="_blank"> `here.` </a>

5. Make programmatic calls to Apple Fitness App. This is not going to happen.  Fitness data lives only on the device (iPhone) and I'd need another iOS app to even make a call to the Fitness API.  However, there are ways to semi- export data from the iOS Health App into a spreadsheet.  A decent explanation can be found <a href="https://www.reddit.com/r/shortcuts/comments/dicerp/attempting_to_create_a_shortcut_for_data_entry_in/" target="_blank">`here.`</a> It uses the iOS Shortcuts app to post to a Mac Numbers spreadsheet.  There are numerous downsides and I'd much rather post the data to S3, but I'm not seeing a way to do this with Shortcuts yet.  There are a few possible upsides.  First. the resulting "shortcut" can be run with one press in iOS, via automation based on time of day, or even a voice command to Siri.  Second, the Health App integrates with many other health-related apps on iOS and is therefore sort of a centralized hub containing larger amounts of data.  Almost all of this data could be exported using the Shortcuts app, but again 

6. Convert the major graphing code to functions.  It is repeated several times and should be simplified.


---

## Contributing

> To get started...

### Step 1

- **Option 1**
    - Fork this repo

- **Option 2**
    - Clone this repo to your local machine using `https://github.com/rtjohn/health-app`

### Step 2

- **HACK AWAY!**

### Step 3

- Create a new pull request using <a href="https://github.com/rtjohn/health-app/compare/" target="_blank">`https://github.com/rtjohn/health-app/compare/`</a>.

---


## Support

None currently.  Maybe submit an issue?
