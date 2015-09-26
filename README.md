# iNotes
Simple iPhone Note Taking App with Dropbox Sync

Run on iOS 8.x and above devices 

## How to Run?

- Clone this repo
- run **sudo gem install cocoapods** if you dont have cocoapods installed already
- run **pod install** to install required dependencies 

##### Note
This project doesn't commit pod dependencies to git, so make sure you run pod install before running it.

## Features

- Option to quickly create, update or delete notes 
- Works completely offline
- Option to sync notes to Dropbox account
- Changes will be automatically synced to dropbox account once internet connection is available 

##### Note 
For the sake of simplicity, iNotes currently store Note content as {randomI}.txt in linked dropbox account
