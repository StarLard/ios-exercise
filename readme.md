# thirteen23 iOS Exercise

## Instructions
### Step 1
Create a custom control for a radial menu that exhibits the following
behavior.

- Tap and hold anywhere on the screen to animate in the menu.
    - If you pressed on the left side of the screen the menu items will
      animate out from where you pressed to the right.
    - If you pressed on the right side of the screen the menu items will
      animate out from where you pressed to the left.
![](./Left-Right.jpg?raw=true)
- Sliding your finger over to one of the menu items will select it.

### Step 2
Use the custom control to build the following application...

![](./Architecture.jpg?raw=true)

- There are 4 screens. Home, 1, 2, and 3. Each screen should have a
  white background and should have the name printed in the center.
- Use the radial menu to move between the screens.
    - From the home screen the menu items should be 1, 2, and 3.
        - Selecting one of the items should cause you to transition to
          the selected screen. The selected screen should slide in from
          the bottom.
    - From screens 1, 2, and 3 the menu items should be h, and the two
      other numbered screens (e.g. if you are on screen 2 the menu
      should contain h, 1, and 3).
        - Selecting one of numbered menu items should cause that
          screen to slide in from the left or the right. In this case
          selecteing 1 would cause screen 1 to slide in from the left.
          Selecting 3 would cause screen 3 to slide in from the right.
        - Selecting h will cause the home screen to slide in from the
          top.

## Notes
- For an example of a radial menu, see the Pinterest iPad app (Tap
  and hold on an item to activate the menu.)
- Also see [wikipedia](http://en.wikipedia.org/wiki/Pie_menu).

## Guidelines
- Use git and send us a link to the repository (Github, Bitbucket, etc...)
- Do not use any third party libraries.
- Do not use storyboards or xibs. Everything should be built
  programmatically.
- Use your own best judgement for the design (size, angles, transtion
  speed, etc...) of the radial menu.
- Assume you are delivering to the client a binary along with your source
  code.
- Your submission will be judged on both code quality and user
  experience.
