# TaskSwap Website

This is a static website for the TaskSwap app that showcases its features and design.

## Required Images

To complete the website, you'll need to add the following images to the `images` folder:

1. `logo.png` - The TaskSwap app logo (already added)
2. `app-preview.png` - A hero image showing the app on a phone
3. `screen-tasks.png` - Screenshot of the tasks screen
4. `screen-profile.png` - Screenshot of the profile screen
5. `screen-social.png` - Screenshot of the social/friends screen
6. `app-devices.png` - Image showing the app on multiple devices

You can create these images by:
- Taking screenshots of your app running on a device or emulator
- Using design tools like Figma, Photoshop, or Canva to create mockups
- Using online mockup generators to place your screenshots in device frames

## How to Deploy the Website

### Option 1: GitHub Pages (Free)

1. Create a new repository on GitHub or use your existing TaskSwap repository
2. Push the website files to the repository
3. Go to the repository settings
4. Scroll down to the "GitHub Pages" section
5. Select the branch that contains your website files (usually `main` or `master`)
6. Select the `/website` folder as the source
7. Click Save
8. Your website will be available at `https://yourusername.github.io/repository-name/website`

### Option 2: Netlify (Free)

1. Sign up for a Netlify account at [netlify.com](https://www.netlify.com/)
2. Click "New site from Git"
3. Connect your GitHub/GitLab/Bitbucket account
4. Select your TaskSwap repository
5. Set the build command to blank (not needed for static sites)
6. Set the publish directory to `website`
7. Click "Deploy site"
8. Your site will be deployed with a Netlify subdomain (e.g., `taskswap.netlify.app`)
9. You can add a custom domain in the site settings if desired

### Option 3: Firebase Hosting (Free tier available)

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login to Firebase: `firebase login`
3. Initialize Firebase in your project: `firebase init`
4. Select "Hosting" when prompted
5. Set the public directory to `website`
6. Configure as a single-page app: "No"
7. Deploy to Firebase: `firebase deploy`
8. Your site will be available at `https://your-project-id.web.app`

## Customization

Feel free to customize the website by:
- Updating the colors in `styles.css` to match your app's theme
- Adding more sections to showcase additional features
- Updating the text content to better describe your app
- Adding animations or interactive elements
- Integrating with your app's backend for features like newsletter signup

## Credits

Developed by RØJINS
