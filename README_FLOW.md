# FoodAI App Flow

## Onboarding Flow

The FoodAI app has a comprehensive onboarding flow that includes:

1. **Splash Screen**: Initial app loading screen with the mango logo
2. **Onboarding Screen**: Introduction to the app's features with food images
3. **Gender Selection Screen**: User selects their gender (Male, Female, Other)
4. **Workout Frequency Screen**: User selects how many workouts they do per week
5. **Home Screen**: Main app interface with food analysis functionality

## Workout Frequency Screen

The newly implemented workout frequency screen allows users to select how many workouts they do per week:

- **0-2**: Workouts now and then
- **3-5**: A few workouts per week
- **6+**: Dedicated athlete

This information is used to calibrate the user's custom nutrition plan.

## Design Improvements

The workout frequency screen features several design improvements:

1. **Enhanced Selection Cards**: Cards with icons that visually represent the workout frequency
2. **Progress Indicator**: Shows the user's progress through the onboarding flow
3. **Animated Transitions**: Smooth animations when selecting options
4. **Material 3 Design**: Following Google's Material 3 Expressive design guidelines
5. **Consistent Typography**: Using Playfair Display for headings and Poppins for body text

## Screenshots

The app flow can be seen in the following screenshots:

1. Splash Screen: `foodai_splash_screen.png`
2. Onboarding Screen: `foodai_onboarding_final.png`
3. Gender Selection Screen: `foodai_gender_screen.png`
4. Workout Frequency Screen: (Current implementation)

## Implementation Details

The workout frequency screen is implemented with:

- Animated containers that respond to user selection
- Custom icon layouts based on the frequency level
- Disabled/enabled next button based on selection state
- Consistent design language with the rest of the app
