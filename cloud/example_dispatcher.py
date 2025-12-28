#!/usr/bin/env python3
"""
Simple example demonstrating the request dispatcher

This script shows how to use the dispatcher without running the full server.
Useful for testing and understanding the request routing.
"""
from cloud_server import RequestDispatcher
from base_handler import BaseHandler


def test_command(command: str):
    """Test a single command and print the result"""
    print(f"\nCommand: {command}")
    print("-" * 60)

    # Create dispatcher
    dispatcher = RequestDispatcher()

    # Convert command to PETSCII and dispatch
    petscii_input = BaseHandler.utf8_to_petscii(command) + b'\x00'
    petscii_output = dispatcher.dispatch(petscii_input)

    # Convert response back to UTF-8
    response = BaseHandler.petscii_to_utf8(petscii_output[:-1])  # Remove null terminator

    print(f"Response:\n{response}")
    print()


def main():
    """Run example commands"""
    print("=" * 60)
    print("C64 Cloud Server - Request Dispatcher Examples")
    print("=" * 60)

    # Test help command
    test_command("help")

    # Test Python eval
    test_command("? 2 + 2")
    test_command("? hex(49152)")
    test_command("? sqrt(144)")

    # Test help topics
    test_command("help python")

    # Test chat (will show fallback if no API key)
    test_command("I: hello")

    # Test CSDB
    test_command("c: search")

    # Test unknown command
    test_command("unknown command")


if __name__ == '__main__':
    main()
