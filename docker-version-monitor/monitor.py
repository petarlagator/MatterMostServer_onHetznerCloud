#!/usr/bin/env python3
"""
Docker Major Version Monitor

Monitors Docker images for major version updates and sends email notifications.
Only notifies when a new major version is available (e.g., PostgreSQL 15 -> 16).
Ignores minor and patch version updates.
"""

import os
import sys
import json
import requests
import smtplib
from datetime import datetime
from pathlib import Path
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Dict, List, Optional, Tuple
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class VersionMonitor:
    """Monitor Docker images for major version updates."""

    def __init__(self, config_path: str):
        """Initialize monitor with configuration.
        
        Args:
            config_path: Path to configuration file
        """
        self.config = self._load_config(config_path)
        self.state_file = Path(self.config['state_file'])
        self.state = self._load_state()

    def _load_config(self, config_path: str) -> Dict:
        """Load configuration from JSON file."""
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load config: {e}")
            sys.exit(1)

    def _load_state(self) -> Dict:
        """Load state file tracking known versions."""
        if self.state_file.exists():
            try:
                with open(self.state_file, 'r') as f:
                    return json.load(f)
            except Exception as e:
                logger.warning(f"Failed to load state file: {e}")
        return {}

    def _save_state(self) -> None:
        """Save state file."""
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        try:
            with open(self.state_file, 'w') as f:
                json.dump(self.state, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save state file: {e}")

    def _parse_version(self, version_str: str) -> Optional[Tuple[int, int, int]]:
        """Parse semantic version string to (major, minor, patch).
        
        Args:
            version_str: Version string like '15.2.0', 'v1.0.0', '1-alpine', etc.
            
        Returns:
            Tuple of (major, minor, patch) or None if parsing fails
        """
        # Remove common prefixes
        version_str = version_str.lstrip('v').split('-')[0]
        
        # Handle special cases
        if version_str == 'latest' or version_str == 'stable':
            return None
            
        parts = version_str.split('.')
        
        try:
            major = int(parts[0]) if len(parts) > 0 else 0
            minor = int(parts[1]) if len(parts) > 1 else 0
            patch = int(parts[2]) if len(parts) > 2 else 0
            return (major, minor, patch)
        except (ValueError, IndexError):
            return None

    def _get_major_version(self, version: Tuple[int, int, int]) -> int:
        """Extract major version from version tuple."""
        return version[0] if version else None

    def _fetch_docker_hub_tags(self, image: str) -> List[str]:
        """Fetch available tags from Docker Hub.
        
        Args:
            image: Image name (e.g., 'library/postgres' or 'mattermost/mattermost-team-edition')
            
        Returns:
            List of available tags
        """
        try:
            # Handle library images (e.g., 'postgres' -> 'library/postgres')
            if '/' not in image:
                image = f"library/{image}"
            
            url = f"https://registry.hub.docker.com/v2/repositories/{image}/tags"
            tags = []
            
            while url:
                logger.debug(f"Fetching: {url}")
                response = requests.get(url, timeout=10)
                response.raise_for_status()
                
                data = response.json()
                tags.extend([tag['name'] for tag in data.get('results', [])])
                
                # Handle pagination
                url = data.get('next')
            
            logger.info(f"Found {len(tags)} tags for {image}")
            return tags
        except Exception as e:
            logger.error(f"Failed to fetch tags for {image}: {e}")
            return []

    def _filter_tags(self, tags: List[str], exclude_patterns: List[str]) -> List[str]:
        """Filter tags based on exclude patterns.
        
        Args:
            tags: List of tags to filter
            exclude_patterns: List of patterns to exclude (e.g., ['-rc', '-beta', 'latest'])
            
        Returns:
            Filtered list of tags
        """
        filtered = []
        for tag in tags:
            # Skip if matches any exclude pattern
            if any(pattern in tag.lower() for pattern in exclude_patterns):
                continue
            filtered.append(tag)
        return filtered

    def check_image(self, image_name: str, current_version: str) -> Optional[Dict]:
        """Check if a new major version is available for an image.
        
        Args:
            image_name: Docker image name
            current_version: Current version running
            
        Returns:
            Dict with update info if major version update found, None otherwise
        """
        logger.info(f"Checking {image_name} (current: {current_version})")
        
        # Parse current version
        current_parsed = self._parse_version(current_version)
        if not current_parsed:
            logger.warning(f"Could not parse current version: {current_version}")
            return None
        
        current_major = self._get_major_version(current_parsed)
        logger.debug(f"Current major version: {current_major}")
        
        # Fetch available tags
        tags = self._fetch_docker_hub_tags(image_name)
        if not tags:
            logger.warning(f"Could not fetch tags for {image_name}")
            return None
        
        # Filter out pre-releases and special tags
        exclude_patterns = ['-rc', '-beta', '-alpha', '-dev', 'latest', 'stable']
        filtered_tags = self._filter_tags(tags, exclude_patterns)
        
        # Find newest major version
        available_versions = []
        for tag in filtered_tags:
            parsed = self._parse_version(tag)
            if parsed:
                available_versions.append((tag, parsed))
        
        if not available_versions:
            logger.warning(f"No valid versions found for {image_name}")
            return None
        
        # Sort by semantic version (descending)
        available_versions.sort(key=lambda x: x[1], reverse=True)
        
        # Find newest version with different major version
        newest_different_major = None
        for tag, parsed in available_versions:
            major = self._get_major_version(parsed)
            if major != current_major and major > current_major:
                newest_different_major = (tag, parsed, major)
                break
        
        if newest_different_major:
            tag, parsed, major = newest_different_major
            logger.info(f"New major version available: {current_major} -> {major} ({tag})")
            return {
                'image': image_name,
                'current_version': current_version,
                'current_major': current_major,
                'new_version': tag,
                'new_major': major,
                'new_parsed': parsed
            }
        
        logger.info(f"No new major version for {image_name}")
        return None

    def send_email(self, updates: List[Dict]) -> bool:
        """Send email notification of major version updates.
        
        Args:
            updates: List of update dictionaries
            
        Returns:
            True if email sent successfully
        """
        if not updates:
            logger.info("No updates to report")
            return True
        
        try:
            smtp_config = self.config['smtp']
            recipient = self.config['notification_email']
            
            # Create email
            msg = MIMEMultipart()
            msg['From'] = smtp_config['from_address']
            msg['To'] = recipient
            msg['Subject'] = f"Docker Major Version Updates Available ({len(updates)} image(s))"
            
            # Create body
            body = "The following Docker images have new MAJOR versions available:\n\n"
            for update in updates:
                body += f"Image: {update['image']}\n"
                body += f"  Current: {update['current_version']} (major: {update['current_major']})\n"
                body += f"  New Major: {update['new_version']} (major: {update['new_major']})\n"
                body += f"  Released: {update['new_parsed']}\n\n"
            
            body += f"\nMonitor checked at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
            body += "\nNote: This is a major version update. Please review the changelog before updating.\n"
            
            msg.attach(MIMEText(body, 'plain'))
            
            # Send email
            logger.info(f"Sending email to {recipient}")
            with smtplib.SMTP(smtp_config['host'], smtp_config['port']) as server:
                if smtp_config.get('use_tls', True):
                    server.starttls()
                if smtp_config.get('username') and smtp_config.get('password'):
                    server.login(smtp_config['username'], smtp_config['password'])
                server.send_message(msg)
            
            logger.info("Email sent successfully")
            return True
        except Exception as e:
            logger.error(f"Failed to send email: {e}")
            return False

    def run(self) -> None:
        """Run the version monitor."""
        logger.info("Starting Docker major version monitor")
        
        updates = []
        
        # Check each image
        for image in self.config.get('images', []):
            image_name = image['name']
            current_version = image['current_version']
            
            update = self.check_image(image_name, current_version)
            if update:
                updates.append(update)
                # Update state
                self.state[image_name] = {
                    'current_version': current_version,
                    'last_check': datetime.now().isoformat(),
                    'found_major_update': True,
                    'new_version': update['new_version']
                }
            else:
                self.state[image_name] = {
                    'current_version': current_version,
                    'last_check': datetime.now().isoformat(),
                    'found_major_update': False
                }
        
        # Save state
        self._save_state()
        
        # Send notification if updates found
        if updates:
            self.send_email(updates)
        
        logger.info("Monitor run completed")


def main():
    """Main entry point."""
    config_path = os.getenv('MONITOR_CONFIG', '/etc/docker-version-monitor/config.json')
    
    if not Path(config_path).exists():
        logger.error(f"Configuration file not found: {config_path}")
        sys.exit(1)
    
    monitor = VersionMonitor(config_path)
    monitor.run()


if __name__ == '__main__':
    main()
