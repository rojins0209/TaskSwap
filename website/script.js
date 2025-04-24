document.addEventListener('DOMContentLoaded', function() {
    // Theme toggle functionality
    const themeToggle = document.querySelector('.theme-toggle');
    const body = document.body;

    // Check for saved theme preference or use device preference
    const savedTheme = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

    if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
        body.classList.add('dark-theme');
        themeToggle.innerHTML = '<i class="fas fa-sun"></i>';
    } else {
        themeToggle.innerHTML = '<i class="fas fa-moon"></i>';
    }

    // Toggle theme when button is clicked
    themeToggle.addEventListener('click', function() {
        body.classList.toggle('dark-theme');

        if (body.classList.contains('dark-theme')) {
            localStorage.setItem('theme', 'dark');
            themeToggle.innerHTML = '<i class="fas fa-sun"></i>';
        } else {
            localStorage.setItem('theme', 'light');
            themeToggle.innerHTML = '<i class="fas fa-moon"></i>';
        }
    });

    // Mobile menu toggle
    const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
    const navLinks = document.querySelector('.nav-links');

    mobileMenuBtn.addEventListener('click', function() {
        navLinks.classList.toggle('active');

        if (navLinks.classList.contains('active')) {
            mobileMenuBtn.innerHTML = '<i class="fas fa-times"></i>';
        } else {
            mobileMenuBtn.innerHTML = '<i class="fas fa-bars"></i>';
        }
    });

    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();

            const targetId = this.getAttribute('href');
            if (targetId === '#') return;

            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                // Close mobile menu if open
                if (navLinks.classList.contains('active')) {
                    navLinks.classList.remove('active');
                    mobileMenuBtn.innerHTML = '<i class="fas fa-bars"></i>';
                }

                // Scroll to target
                window.scrollTo({
                    top: targetElement.offsetTop - 80, // Adjust for header height
                    behavior: 'smooth'
                });
            }
        });
    });

    // Header scroll behavior
    const header = document.querySelector('header');
    let lastScrollTop = 0;
    let scrollTimer;

    window.addEventListener('scroll', function() {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

        // Add box shadow when scrolled
        if (scrollTop > 10) {
            header.classList.add('scrolled');
        } else {
            header.classList.remove('scrolled');
        }

        // Hide header when scrolling down, show when scrolling up
        if (scrollTop > lastScrollTop && scrollTop > 200) {
            // Scrolling down
            header.classList.add('hidden');
        } else {
            // Scrolling up
            header.classList.remove('hidden');
        }

        lastScrollTop = scrollTop;

        // Show header when user stops scrolling
        clearTimeout(scrollTimer);
        scrollTimer = setTimeout(function() {
            header.classList.remove('hidden');
        }, 1000);
    });

    // Parallax effect for hero section
    const heroSection = document.querySelector('.hero-container');
    const heroContent = document.querySelector('.hero-content');
    const heroImage = document.querySelector('.hero-image');

    if (heroSection && window.innerWidth > 768) {
        window.addEventListener('scroll', function() {
            const scrollTop = window.pageYOffset;
            const heroOffset = heroSection.offsetTop;
            const scrollPosition = scrollTop - heroOffset;

            if (scrollPosition > -window.innerHeight && scrollPosition < window.innerHeight) {
                heroContent.style.transform = `translateY(${scrollPosition * 0.1}px)`;
                heroImage.style.transform = `translateY(${scrollPosition * 0.15}px)`;
            }
        });
    }

    // Add animation classes on scroll
    const animateOnScroll = function() {
        const elements = document.querySelectorAll('.section-header, .feature-card, .showcase-item, .download, .aura-card, .footer-column');

        elements.forEach(element => {
            const elementPosition = element.getBoundingClientRect().top;
            const windowHeight = window.innerHeight;

            if (elementPosition < windowHeight - 100) {
                element.classList.add('animate-in');
            }
        });
    };

    // Add animation classes to elements
    const addAnimationClasses = function() {
        // Feature cards staggered animation
        const featureCards = document.querySelectorAll('.feature-card');
        featureCards.forEach((card, index) => {
            card.style.transitionDelay = `${index * 0.1}s`;
        });

        // Showcase items staggered animation
        const showcaseItems = document.querySelectorAll('.showcase-item');
        showcaseItems.forEach((item, index) => {
            item.style.transitionDelay = `${index * 0.15}s`;
        });

        // Footer columns staggered animation
        const footerColumns = document.querySelectorAll('.footer-column');
        footerColumns.forEach((column, index) => {
            column.style.transitionDelay = `${index * 0.1}s`;
        });
    };

    // Add CSS classes for animations
    const style = document.createElement('style');
    style.textContent = `
        .animate-in {
            opacity: 1;
            transform: translateY(0);
        }

        .section-header, .feature-card, .showcase-item, .download, .aura-card, .footer-column {
            opacity: 0;
            transform: translateY(30px);
            transition: opacity 0.6s ease, transform 0.6s ease;
        }

        header {
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        header.hidden {
            transform: translateY(-100%);
        }
    `;
    document.head.appendChild(style);

    // Run animation setup
    addAnimationClasses();

    // Run animation check on load and scroll
    window.addEventListener('load', animateOnScroll);
    window.addEventListener('scroll', animateOnScroll);

    // Add showcase controls functionality
    const showcaseItems = document.querySelectorAll('.showcase-item');
    const showcaseContainer = document.querySelector('.showcase-container');

    if (showcaseContainer && showcaseItems.length > 0) {
        // Create showcase controls
        const showcaseControls = document.createElement('div');
        showcaseControls.className = 'showcase-controls';

        for (let i = 0; i < showcaseItems.length; i++) {
            const dot = document.createElement('div');
            dot.className = 'showcase-dot' + (i === 0 ? ' active' : '');
            dot.dataset.index = i;
            showcaseControls.appendChild(dot);

            dot.addEventListener('click', function() {
                // Remove active class from all dots
                document.querySelectorAll('.showcase-dot').forEach(d => {
                    d.classList.remove('active');
                });

                // Add active class to clicked dot
                this.classList.add('active');

                // Scroll to the corresponding showcase item
                showcaseItems[i].scrollIntoView({
                    behavior: 'smooth',
                    block: 'nearest',
                    inline: 'center'
                });
            });
        }

        // Add controls to the DOM
        const showcaseSection = document.querySelector('.showcase');
        showcaseSection.appendChild(showcaseControls);
    }
});
