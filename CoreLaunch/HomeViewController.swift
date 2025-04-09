        }
        print("----------------------------------")

        // Temporarily disable delegate/datasource to prevent redraw during animation
        print("DEBUG: Nil-ing table delegate/datasource before present")
        tableView.delegate = nil
        tableView.dataSource = nil
        
        present(navController, animated: true) { [weak self] in
            // Restore delegate/datasource after presentation completes
            print("DEBUG: Restoring table delegate/datasource after present")
            self?.tableView.delegate = self
            self?.tableView.dataSource = self
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset visual elements to avoid flicker during reuse
        print("--- DEBUG: AppCell.prepareForReuse (cell: \(self)) ---")
        nameLabel.text = nil
        // colorIndicator.backgroundColor = .clear // Commenting out again - should be safe now
        contentView.backgroundColor = .clear // Reset background as well
        backgroundColor = .clear
        nameLabel.textColor = .label // Reset text color
    }
}